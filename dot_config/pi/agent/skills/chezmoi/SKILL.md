---
name: chezmoi
description: Guide for managing dotfiles with chezmoi. Use when the user says 'chezmoi that', 'chezmoi it', 'chezmoi push', 'chezmoi pull', 'add to chezmoi', or asks about dotfile management.
---

**⚠️ NEVER run `chezmoi apply --force` without explicit user approval.** It overwrites live dotfiles with the chezmoi source state, destroying any changes made outside chezmoi. Always edit source files and let the user decide when to apply.

## TL;DR

Chezmoi is a dotfile manager. You maintain a source directory (`~/.local/share/chezmoi`) that defines your dotfiles. Running `chezmoi apply` writes them to your home directory with the correct paths, permissions, and attributes. Changes are tracked in git.

## Core commands

```bash
chezmoi add <path>                     # Add a file to source state
chezmoi re-add <path>                  # Update source state from on-disk file
chezmoi apply                          # Apply source state to home
chezmoi diff                           # Show pending changes
chezmoi status                         # Show managed files status
chezmoi forget <target-path>           # Stop managing (keeps file on disk)
chezmoi destroy <target-path>          # Stop managing AND delete
chezmoi edit <target-path>             # Edit file in source state
chezmoi merge <target-path>            # Three-way merge
chezmoi cd                             # Open shell in source directory
chezmoi git <args>                     # Run git in source directory
```

See `chezmoi <command> --help` for less common operations.

## Detecting changes

Run the review script for a full drift report:

```bash
bash scripts/chezmoi-review
```

It checks: managed file drift, uncommitted source changes, files newer than HEAD, unmanaged files, and missing targets.

### Handling deleted targets

When a file exists in chezmoi source but is missing from your home:

1. **Ask the user**: "You deleted `~/.config/foo/bar`. Intentional (remove from chezmoi) or accidental (restore)?"
2. **If intentional**: `chezmoi destroy ~/.config/foo/bar`
3. **If accidental**: `chezmoi apply` restores from source

## Workflow: "Chezmoi that" / "Chezmoi it"

When the user says "chezmoi that", "chezmoi it", or "add to chezmoi":

1. **File exists on disk?** Use `chezmoi re-add <target-path>`
2. **File doesn't exist yet?** Use `chezmoi add <path>` — it handles naming automatically
3. **Secrets?** Use `chezmoi add --secrets warning <path>` — it'll flag tokens/passwords
4. **Git ops?** Use `chezmoi git pull --rebase`, `chezmoi git add`, `chezmoi git commit`, `chezmoi git push`
5. **Verify?** `chezmoi status` and `chezmoi git status` should be clean

## Pushing chezmoi

1. **Pull first**: `chezmoi git pull --rebase`
2. **Review drift**: `bash scripts/chezmoi-review`
3. **Challenge about secrets**: ask if any new files contain tokens, passwords, or private data
4. **Stage, commit, push**: `chezmoi git add -A && chezmoi git commit -m "message" && chezmoi git push`
5. **Verify**: `chezmoi git status` should be clean

## Pulling chezmoi

1. **Pull**: `chezmoi git pull --rebase`
2. **Apply**: `chezmoi apply` — writes all source files to their target locations
3. **Verify**: `chezmoi diff` should be empty
4. **If apply fails**: Never use `--force`. Run `chezmoi diff` and `chezmoi-review` to resolve the drift first.

## Ignoring files

### For new files (never tracked)

Add patterns to `.chezmoiignore`. Patterns are relative to the source directory.

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

1. **Remove from source state**: `chezmoi forget <target-path>`
2. **Add to .chezmoiignore**: Add the pattern so it stays ignored going forward
3. **Commit**: `chezmoi git add -A && chezmoi git commit -m "chore: ignore <file>"`

Example — ignoring `lazy-lock.json`:
```bash
chezmoi forget ~/.config/nvim/lazy-lock.json
echo "dot_config/nvim/lazy-lock.json" >> .chezmoiignore
chezmoi git add -A && chezmoi git commit -m "chore: ignore nvim lazy-lock.json"
```

## Scripts & package management

Helper scripts (`scripts/chezmoi-add`) and package lists (`shelly-packages.txt`) are in development. See `chezmoi-add --help` for available helpers.

## Troubleshooting

- **"not managed"** — File isn't in the source state. Run `chezmoi add <path>` or check `.chezmoiignore`
- **"cannot add chezmoi file to chezmoi"** — You're inside the source directory. Use `chezmoi cd` instead
- **File changed since chezmoi last wrote it** — Target was modified externally. Either `chezmoi apply` to overwrite, or `chezmoi re-add` to update the source
- **Permission issues** — Check `private_`, `readonly_`, or `executable_` prefixes
- **Template errors** — Check `.tmpl` files for Go template syntax
- **`.chezmoiignore` alone doesn't stop tracking** — If a file is already in source state, remove it first (delete from source dir + add to ignore)
- **`chezmoi apply` fails with TTY errors** — May be caused by encrypted files or interactive prompts. Check `chezmoi diff`
- **Avoid manual install scripts** — Prefer adding packages to `shelly-packages.txt`
- **Want to merge external edits into chezmoi** — Use `chezmoi merge <target-path>` for a three-way merge
- **Added a file without right attributes** — Use `chezmoi chattr` to add/change attributes
