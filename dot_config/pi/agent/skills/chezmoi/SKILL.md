---
name: chezmoi
description: Guide for managing dotfiles with chezmoi. Covers source state, apply, file naming conventions (dot_, private_, executable_), adding files, ignoring files, templates, and common workflows. Use when the user says 'chezmoi that', 'chezmoi it', 'chezmoi push', 'chezmoi pull', 'add to chezmoi', or asks about dotfile management.
---

**⚠️ NEVER run `chezmoi apply --force` without explicit user approval.** It overwrites live dotfiles with the chezmoi source state, destroying any changes made outside chezmoi (e.g., `pi install`, manual edits, package.json updates). Always edit source files and let the user decide when to apply.

# Chezmoi Skill

## Prerequisites

- `chezmoi` installed (`which chezmoi`)
- Source path known (`chezmoi source-path`, default: `~/.local/share/chezmoi`)
- Git remote configured in the source repo

## Core Concepts

Chezmoi manages dotfiles through a **source state** directory that maps to the target home directory. The source repo is typically at `~/.local/share/chezmoi`.

State is stored in `~/.config/chezmoi/chezmoistate.boltdb`.

### Source → Target mapping

| Source name | Target path |
|---|---|
| `dot_foo` | `~/.foo` |
| `dot_config/bar/baz` | `~/.config/bar/baz` |
| `private_dot_secret` | `~/.secret` (not in git) |
| `scripts/hello` | `~/bin/hello` (executable script) |
| `templates/file.txt.tmpl` | `~/file.txt` (rendered via Go template) |

### File naming conventions

| Prefix | Meaning | Git? |
|--------|---------|------|
| `dot_` | Dotfile/directory | Yes |
| `private_` | Secret, excluded from git | No |
| `executable_` | Make executable on apply | Yes |
| `readonly_` | Read-only on apply | Yes |
| `symlink_` | Create symlink on apply | Yes |
| `onapply_` | Run this script every time chezmoi applies | Yes |
| `onchange_` | Run this script when its source file changes | Yes |
| `create_` | Create on apply, don't track changes | Yes |
| `once_` | Run once, never again | Yes |

### Common commands

```bash
chezmoi source-path                    # Show source directory
chezmoi add <path>                     # Add file to source state
chezmoi add --secrets <path>           # Add + scan for secrets (error|ignore|warning)
chezmoi add --encrypt <path>           # Add + encrypt
chezmoi add --template <path>          # Add as template
chezmoi re-add <path>                  # Update source state from on-disk file
chezmoi apply                          # Apply source state to home
chezmoi diff                           # Show pending changes (source vs target)
chezmoi diff --reverse                 # Show target vs source (opposite direction)
chezmoi status                         # Show managed files status
chezmoi edit <target-path>             # Edit file in source state
chezmoi edit <target-path> --apply     # Edit source state AND apply it
chezmoi merge <target-path>            # Three-way merge (dest vs target vs source)
chezmoi managed                        # List all managed targets
chezmoi unmanaged                      # List files not managed by chezmoi
chezmoi forget <target-path>           # Stop managing a file (keeps on disk)
chezmoi destroy <target-path>          # Stop managing AND delete the file
chezmoi chattr template <target-path>  # Change file attribute (e.g. make it a template)
chezmoi init                           # Initialize chezmoi from remote repo
chezmoi update                         # Pull and apply changes from remote
chezmoi cd                             # Open shell in source directory
chezmoi git <args>                     # Run git in source directory
```

### Removing files from chezmoi

**`chezmoi forget <target-path>`** — Remove from chezmoi source state but keep the file on disk. Use this when you want to stop managing a file but keep it as-is.

**`chezmoi destroy <target-path>`** — Remove from chezmoi source state AND delete the target file. Use this when you want to completely remove the file.

## Detecting uncommitted / drifted changes

Before committing or pushing, always check for drift across three layers:

```bash
cd ~/.local/share/chezmoi

# 1. chezmoi-managed files whose live state differs from source
chezmoi status

# 2. chezmoi source changes not yet committed
git status

# 3. Files on disk newer than HEAD that aren't tracked
find ~ -maxdepth 1 -newer .git/refs/heads/main -type f 2>/dev/null
find ~/.config -newer .git/refs/heads/main -type f 2>/dev/null

# 4. Files on disk that chezmoi doesn't manage at all
chezmoi unmanaged

# 5. Files in chezmoi source that are MISSING from live filesystem
git ls-files --deleted 2>/dev/null || true
# Or: find files in the source dir that have no corresponding target
```

**Interpreting results:**

| Output | Meaning | Action |
|---|---|---|
| `chezmoi status` shows `M` | Live file ≠ source state | `chezmoi re-add <path>` to sync source, or `chezmoi apply` to overwrite live |
| `git status` shows changes | Source edited but not committed | `git add && git commit` |
| `find` files newer than HEAD | Files changed after last commit but not in chezmoi | `chezmoi add <path>` |
| `chezmoi unmanaged` | Files on disk, not tracked | Decide: add to chezmoi, ignore, or leave alone |
| Source file exists but target is **missing** | User deleted the live file | **Ask the user**: remove from chezmoi (`chezmoi destroy`) or restore? |

**Handling deleted targets:**

When a file exists in chezmoi source but is missing from the live filesystem:

1. **Ask the user**: "You deleted `~/.config/foo/bar`. Intentional (remove from chezmoi) or accidental (restore)?"
2. **If intentional**: `chezmoi destroy ~/.config/foo/bar` — removes from both source and disk
3. **If accidental**: `chezmoi apply` — restores from source

**Quick one-liner for all of the above:**
```bash
bash ~/.local/share/chezmoi/dot_config/pi/agent/skills/chezmoi/scripts/chezmoi-review
```

## Understanding `chezmoi status` vs `git status`

These show **completely different things**:

| Command | Compares | Shows |
|---|---|---|
| `chezmoi status` | **live filesystem** vs **chezmoi source** | Managed files where on-disk ≠ source state |
| `git status` | **chezmoi source** vs **git HEAD** | Source files not yet committed |

**Example:** After `pi install`, `chezmoi status` shows `M .config/pi/agent/settings.json` (live file changed). `git status` is clean (nothing committed yet). After editing a chezmoi source file manually, `git status` shows the change but `chezmoi status` is clean (source matches live).

**Both must be clean before push:**
```bash
chezmoi status    # should be empty — no live drift
git status        # should be empty — nothing to commit
```

## Important: `package.json` is NOT managed by chezmoi

The file `~/.config/pi/agent/npm/package.json` (npm dependencies for pi extensions) is **not tracked by chezmoi**. Changes from `pi install` update settings.json but do NOT modify package.json.

- `pi install` → updates `settings.json` packages array + installs to `node_modules`
- `package.json` → tracks exact versions, but lives outside chezmoi
- If you want package.json tracked, add the npm directory to chezmoi source

## Updating live files back to chezmoi

When you've edited a file on disk (the target) and want to update the chezmoi source state to match:

```bash
# Re-add the on-disk file into the chezmoi source state
chezmoi re-add ~/.config/oh-my-posh/zheak.omp.json
# Or for all modified files at once:
chezmoi re-add
```

This copies the current on-disk content back into the source state, preserving any special attributes (encrypted, template, etc.). Then commit and push normally.

**Don't** reset to origin/main or manually edit the source file — `chezmoi re-add` does it correctly.

## Workflow: "Chezmoi that" / "Chezmoi it"

When the user says "chezmoi that", "chezmoi it", or "add to chezmoi":

1. **Check if file already exists on disk** (the target). If yes, use `chezmoi re-add <target-path>` instead of copying.
2. If the file doesn't exist yet, **copy** it into the chezmoi source directory with correct naming.
3. **Challenge about secrets**: if the file contains tokens, passwords, API keys, or anything sensitive, use `chezmoi add --encrypt` or rename with `private_` prefix.
4. **Check for secrets**: run `chezmoi add --secrets warning <path>` or `chezmoi diff` to catch anything that shouldn't be public.
5. **Git add + commit + push** in the source repo (always `git pull --rebase` first).
6. Verify with `chezmoi status` or `git status`.

### Example: Re-adding a live edit

```bash
# User edited ~/.config/oh-my-posh/zheak.omp.json directly
cd ~/.local/share/chezmoi
chezmoi re-add ~/.config/oh-my-posh/zheak.omp.json
git add dot_config/oh-my-posh/zheak.omp.json
git commit -m "feat: update oh-my-posh theme"
git push
```

### Example: Adding a new config file

```bash
# New file not yet on disk, user provided content
mkdir -p ~/.local/share/chezmoi/dot_config/nvim
cp ~/.config/nvim/init.lua ~/.local/share/chezmoi/dot_config/nvim/init.lua
cd ~/.local/share/chezmoi
git add dot_config/nvim/init.lua
git commit -m "feat: add nvim init"
git push
```

### Example: Adding a script

```bash
# Scripts go in scripts/ prefix — chezmoi makes them executable and puts them in ~/bin
cp myscript.sh ~/.local/share/chezmoi/scripts/myscript
cd ~/.local/share/chezmoi
git add scripts/myscript
git commit -m "feat: add myscript"
git push
```

## Pushing chezmoi

When the user asks to push chezmoi/dotfiles:

1. **cd to source dir**: `cd ~/.local/share/chezmoi`
2. **Pull first**: `git pull --rebase` — never push without pulling first
3. **Review step — flag dotfiles/configs newer than HEAD**:
   ```bash
   cd ~/.local/share/chezmoi
   # Find dotfiles in ~/ and ~/.config/ newer than last commit
   find ~ -maxdepth 1 \( -newer .git/refs/heads/main -type f -name '.*' -o -newer .git/refs/heads/main -type d -name '.*' \) \
     -o -path "$HOME/.config/*" -newer .git/refs/heads/main -type f \
     2>/dev/null | grep -v -E 'node_modules|\.git/|\.cache/|\.local/share/shell|\.config/(discord|slack|zoom|teams|code)/' \
     | grep -v -E '\.(log|jsonl|json|tmp|swp)$' \
     | grep -v -E 'Cookies|LEV|GPUCache|Dawn|TransportSecurity|Network.*State|session\.json'
   ```
   Review each one — should it be committed? If yes, `chezmoi re-add <target-path>` or `chezmoi add <target-path>`. Note: some `~/.*` files are symlinks into `~/.config/` — skip duplicates.
4. **Scan for changes**: `chezmoi diff` (target changes) and `git diff HEAD` (source changes)
5. **Check for unmanaged files**: `chezmoi unmanaged` — these are files on disk that aren't tracked
6. **Check for secrets in new files**: `chezmoi add --secrets warning` or manually review
7. **Challenge about public repo**: ask if any new files contain secrets, tokens, or private data
8. **Stage, commit, push**: `git add -A && git commit -m "message" && git push`
9. **Verify**: `git status` should be clean

## Pulling chezmoi

When the user asks to pull chezmoi/dotfiles or set up a new machine:

1. **cd to source dir**: `cd ~/.local/share/chezmoi`
2. **Pull**: `git pull --rebase`
3. **Apply**: `chezmoi apply` — this writes all source files to their target locations
4. **Verify**: `chezmoi diff` should be empty (no pending changes)
5. **Run onapply scripts**: any `onapply_` scripts run automatically during `chezmoi apply`
6. **Check for errors**: `chezmoi status` and review any warnings

## Managing pi extensions

Extensions are installed via the `pi` CLI, **not** `chezmoi add`:

```bash
# Install (adds to settings.json + installs npm package)
pi install npm:@foo/bar

# Remove
pi remove npm:@foo/bar

# List installed
pi list
```

**Where `pi install` writes:**
- Settings: `~/.config/pi/agent/settings.json` → adds to `packages` array
- Package: `~/.config/pi/agent/npm/node_modules/<package>`

**Syncing with chezmoi:** After `pi install`, `chezmoi status` will show `M .config/pi/agent/settings.json`. Commit the settings.json change — the npm package itself is installed separately.

**Untracked npm packages:** If a package exists in `node_modules` but not in settings.json `packages`, it was installed manually (e.g., `npm install`). Run `pi install npm:<package>` to register it properly.

## Managing package lists

### shelly-packages.txt

Packages to install via shelly (Arch/Manjaro unified package manager).

```bash
# Edit the package list
echo "new-package" >> ~/.local/share/chezmoi/shelly-packages.txt

# Remove a package — edit the file and remove the line
# Then re-add to update source state:
cd ~/.local/share/chezmoi
chezmoi re-add ~/.local/share/chezmoi/shelly-packages.txt
git commit -m "feat: add new-package to shelly-packages"
git push

# Install after pushing/pulling:
chezmoi apply
```



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
cd ~/.local/share/chezmoi
# 1. Remove from source state
rm dot_config/nvim/lazy-lock.json
# 2. Add to ignore (edit .chezmoiignore)
echo "dot_config/nvim/lazy-lock.json" >> .chezmoiignore
# 3. Commit both
git add .chezmoiignore dot_config/nvim/lazy-lock.json
git commit -m "chore: ignore nvim lazy-lock.json"
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

## Templates

Chezmoi supports Go templates for dynamic content. Use `.tmpl` extension:

```bash
# Source file with template
dot_config/git/config.tmpl

# Contains {{ .username }} or other variables
# Rendered on apply using chezmoi data (env vars, command output, etc.)
```

Or set the `template` attribute on an existing file:
```bash
chezmoi chattr template ~/.zshrc
```

## Troubleshooting

- **"not managed"** — File isn't in the source state. Run `chezmoi add <path>` or check if it's in `.chezmoiignore`
- **"cannot add chezmoi file to chezmoi"** — You're inside the source directory. Use git directly instead of `chezmoi add`
- **File changed since chezmoi last wrote it** — The target was modified externally. Either `chezmoi apply` to overwrite, or `chezmoi re-add` to update the source
- **Permission issues** — Check `private_`, `readonly_`, or `executable_` prefixes
- **Template errors** — Check `.tmpl` files for Go template syntax
- **`.chezmoiignore` alone doesn't stop tracking** — If a file is already in source state, you must remove it first (delete from source dir + add to ignore)
- **`chezmoi apply` fails with TTY errors** — May be caused by encrypted files or interactive prompts. Check `chezmoi diff` for details
- **Avoid manual install scripts** — Prefer adding packages to `shelly-packages.txt` rather than writing custom install scripts. System packages are managed by the package manager and will be tracked properly.
- **Want to merge external edits into chezmoi** — Use `chezmoi merge <target-path>` for a three-way merge (destination vs target vs source)
- **Added a file without right attributes** — Use `chezmoi chattr` to add/change attributes: `chezmoi chattr template,private ~/.netrc`

## State corruption

If you get errors like `inconsistent state` or `chezmoi diff` says files are "not managed" when they clearly are:

1. **Don't delete the state file** — it makes chezmoi forget everything
2. Instead, run `chezmoi apply` — it rebuilds the state by scanning the source
3. If that still fails, then: `rm ~/.config/chezmoi/chezmoistate.boltdb && chezmoi apply`

## Naming convention changes

Chezmoi renamed its script prefixes:
- `run_onchange_` → `onchange_` (run when source file changes)
- `run_onapply_` → `onapply_` (run every apply)

Migrate: `git mv run_onchange_X.sh onchange_X.sh` and `git mv run_onapply_X.sh onapply_X.sh`

## chezmoi diff vs git diff

`chezmoi diff` shows changes between **source state and target** (on-disk files). Paths in output are target paths (e.g. `.config/git/config`).

`git diff` shows changes between **git HEAD and working tree**. Paths are source paths (e.g. `dot_config/git/config`).

To inspect source-state changes: `git diff HEAD -- <source-path>`
To inspect target changes: `chezmoi diff` or `chezmoi diff --source-path <source-path>`

## Secret handling

Before committing anything to the public repo:

1. **`chezmoi add --secrets warning <path>`** — scans for secrets when adding
2. **`chezmoi add --encrypt <path>`** — encrypts the file with age
3. **`private_` prefix** — file is managed by chezmoi but never committed to git
4. **`.chezmoiignore`** — for files that should never be tracked
5. **Challenge the user** if a file looks like it contains tokens, passwords, API keys, or private data
6. **bitwarden** — we use bitwarden for secret management. When the user has it set up, secrets should go to bitwarden, not chezmoi.
