---
name: chezmoi
description: Guide for managing dotfiles with chezmoi. Use when the user says 'chezmoi that', 'chezmoi it', 'chezmoi push', 'chezmoi pull', 'add to chezmoi', or asks about dotfile management.
---

**⚠️ NEVER run `chezmoi apply --force` without explicit user approval.** It overwrites live dotfiles with the chezmoi source state, destroying any changes made outside chezmoi. Always edit source files and let the user decide when to apply.

## Core concepts

Chezmoi manages dotfiles through a source state directory (`~/.local/share/chezmoi`). Source files use naming conventions to determine their target path and attributes:

| Prefix | Meaning | Git? |
|--------|---------|------|
| `dot_` | Dotfile (e.g. `dot_zshrc` → `~/.zshrc`) | Yes |
| `private_` | Secret, excluded from git | No |
| `executable_` | Make executable on apply | Yes |
| `readonly_` | Read-only on apply | Yes |
| `symlink_` | Create symlink on apply | Yes |

## Common commands

```bash
chezmoi source-path                    # Show source directory
chezmoi add <path>                     # Add file to source state
chezmoi add --secrets <path>           # Add + scan for secrets (error|ignore|warning)
chezmoi re-add <path>                  # Update source state from on-disk file
chezmoi apply                          # Apply source state to home
chezmoi diff                           # Show pending changes (source vs target)
chezmoi diff --reverse                 # Show target vs source (opposite direction)
chezmoi status                         # Show managed files status
chezmoi managed                        # List all managed targets
chezmoi unmanaged                      # List files not managed by chezmoi
chezmoi forget <target-path>           # Stop managing a file (keeps on disk)
chezmoi destroy <target-path>          # Stop managing AND delete the file
chezmoi edit <target-path>             # Edit file in source state
chezmoi edit <target-path> --apply     # Edit source state AND apply it
chezmoi merge <target-path>            # Three-way merge (dest vs target vs source)
chezmoi cd                             # Open shell in source directory
chezmoi git <args>                     # Run git in source directory
```

## Detecting changes

Run the review script to see all drift in one actionable list:

```bash
bash ~/.local/share/chezmoi/dot_config/pi/agent/skills/chezmoi/scripts/chezmoi-review
```

This combines `chezmoi status`, `git status`, files newer than HEAD, unmanaged files, and missing targets into a single report. Each section tells you what to do next.

### Handling deleted targets

When a file exists in chezmoi source but is missing from the live filesystem:

1. **Ask the user**: "You deleted `~/.config/foo/bar`. Intentional (remove from chezmoi) or accidental (restore)?"
2. **If intentional**: `chezmoi destroy ~/.config/foo/bar` — removes from both source and disk
3. **If accidental**: `chezmoi apply` — restores from source

## Workflow: "Chezmoi that" / "Chezmoi it"

When the user says "chezmoi that", "chezmoi it", or "add to chezmoi":

1. **Check if file already exists on disk** (the target). If yes, use `chezmoi re-add <target-path>` instead of copying.
2. If the file doesn't exist yet, use `chezmoi add <path>` — it handles naming and attributes automatically.
3. **Challenge about secrets**: if the file contains tokens, passwords, API keys, or anything sensitive, use `chezmoi add --encrypt` or rename with `private_` prefix.
4. **Check for secrets**: `chezmoi add --secrets warning <path>` catches anything that shouldn't be public.
5. **Git operations**: use `chezmoi git pull --rebase`, `chezmoi git add`, `chezmoi git commit`, `chezmoi git push`.
6. **Verify**: `chezmoi status` and `git status` should be clean.

### Example: Re-adding a live edit

```bash
# User edited ~/.config/oh-my-posh/zheak.omp.json directly
chezmoi re-add ~/.config/oh-my-posh/zheak.omp.json
chezmoi git add dot_config/oh-my-posh/zheak.omp.json
chezmoi git commit -m "feat: update oh-my-posh theme"
chezmoi git push
```

### Example: Adding a new config file

```bash
# New file not yet on disk, user provided content
chezmoi add --stdin dot_config/nvim/init.lua "feat: add nvim init"
```

### Example: Adding a script

```bash
# Scripts go in scripts/ prefix — chezmoi makes them executable and puts them in ~/bin
chezmoi add scripts/myscript
chezmoi git commit -m "feat: add myscript"
chezmoi git push
```

## Pushing chezmoi

When the user asks to push chezmoi/dotfiles:

1. **Pull first**: `chezmoi git pull --rebase` — never push without pulling first
2. **Review step — flag dotfiles/configs newer than HEAD**:
   ```bash
   chezmoi cd
   find ~ -maxdepth 1 \( -newer .git/refs/heads/main -type f -name '.*' -o -newer .git/refs/heads/main -type d -name '.*' \) \
     -o -path "$HOME/.config/*" -newer .git/refs/heads/main -type f \
     2>/dev/null | grep -v -E 'node_modules|\.git/|\.cache/|\.local/share/shell|\.config/(discord|slack|zoom|teams|code)/' \
     | grep -v -E '\.(log|jsonl|json|tmp|swp)$' \
     | grep -v -E 'Cookies|LEV|GPUCache|Dawn|TransportSecurity|Network.*State|session\.json'
   ```
   Review each one — should it be committed? If yes, `chezmoi re-add <target-path>` or `chezmoi add <target-path>`. Note: some `~/.*` files are symlinks into `~/.config/` — skip duplicates.
3. **Scan for changes**: `chezmoi diff` (target changes) and `chezmoi git diff HEAD` (source changes)
4. **Check for unmanaged files**: `chezmoi unmanaged` — these are files on disk that aren't tracked
5. **Check for secrets in new files**: `chezmoi add --secrets warning` or manually review
6. **Challenge about public repo**: ask if any new files contain secrets, tokens, or private data
7. **Stage, commit, push**: `chezmoi git add -A && chezmoi git commit -m "message" && chezmoi git push`
8. **Verify**: `chezmoi git status` should be clean

## Pulling chezmoi

When the user asks to pull chezmoi/dotfiles or set up a new machine:

1. **Pull**: `chezmoi git pull --rebase`
2. **Apply**: `chezmoi apply` — this writes all source files to their target locations
3. **Verify**: `chezmoi diff` should be empty (no pending changes)
4. **Run onapply scripts**: any `onapply_` scripts run automatically during `chezmoi apply`
5. **Check for errors**: `chezmoi status` and review any warnings

## Ignoring files

### For new files (never tracked)

Add patterns to `~/.local/share/chezmoi/.chezmoiignore`. Patterns are relative to the source directory.

Common patterns:
```
# Generated lock files
*/lazy-lock.json

# Session data
agent/sessions/

# Private tokens
**/auth.json

# Ephemeral/temp files
**/*.tmp
**/*.swp
**/.DS_Store
```

### For already-tracked files

If a file is already in chezmoi's source state, adding it to `.chezmoiignore` alone won't work. You must:

1. **Remove from source state**: Delete the source file from `~/.local/share/chezmoi/` (or use `chezmoi forget`)
2. **Add to .chezmoiignore**: Add the pattern so it stays ignored going forward
3. **Commit both changes**

Example — ignoring `lazy-lock.json`:
```bash
chezmoi cd
# 1. Remove from source state
rm dot_config/nvim/lazy-lock.json
# 2. Add to ignore (edit .chezmoiignore)
echo "dot_config/nvim/lazy-lock.json" >> .chezmoiignore
# 3. Commit both
chezmoi git add .chezmoiignore dot_config/nvim/lazy-lock.json
chezmoi git commit -m "chore: ignore nvim lazy-lock.json"
```

## Scripts

Helper scripts in `scripts/` subdirectory for common chezmoi tasks.

### chezmoi-add

Add a file or directory to chezmoi source state with correct naming and git commit.

```bash
# Add a single file
chezmoi-add ~/.config/nvim/init.lua "feat: add nvim init"

# Add a directory
chezmoi-add ~/.config/gh aliases/ "feat: add gh aliases"

# Add from stdin (for generated content)
echo "content" | chezmoi-add --stdin dot_config/foo/bar "chore: add bar"
```

## Managing package lists

### shelly-packages.txt

Packages to install via shelly (Arch/Manjaro unified package manager).

```bash
# Edit the package list
echo "new-package" >> ~/.local/share/chezmoi/shelly-packages.txt

# Remove a package — edit the file and remove the line
# Then re-add to update source state:
chezmoi cd
chezmoi re-add ~/.local/share/chezmoi/shelly-packages.txt
chezmoi git commit -m "feat: add new-package to shelly-packages"
chezmoi git push

# Install after pushing/pulling:
chezmoi apply
```

## Troubleshooting

- **"not managed"** — File isn't in the source state. Run `chezmoi add <path>` or check if it's in `.chezmoiignore`
- **"cannot add chezmoi file to chezmoi"** — You're inside the source directory. Use `chezmoi cd` instead, then use git directly
- **File changed since chezmoi last wrote it** — The target was modified externally. Either `chezmoi apply` to overwrite, or `chezmoi re-add` to update the source
- **Permission issues** — Check `private_`, `readonly_`, or `executable_` prefixes
- **Template errors** — Check `.tmpl` files for Go template syntax
- **`.chezmoiignore` alone doesn't stop tracking** — If a file is already in source state, you must remove it first (delete from source dir + add to ignore)
- **`chezmoi apply` fails with TTY errors** — May be caused by encrypted files or interactive prompts. Check `chezmoi diff` for details
- **Avoid manual install scripts** — Prefer adding packages to `shelly-packages.txt` rather than writing custom install scripts. System packages are managed by the package manager and will be tracked properly.
- **Want to merge external edits into chezmoi** — Use `chezmoi merge <target-path>` for a three-way merge (destination vs target vs source)
- **Added a file without right attributes** — Use `chezmoi chattr` to add/change attributes: `chezmoi chattr template,private ~/.netrc`
