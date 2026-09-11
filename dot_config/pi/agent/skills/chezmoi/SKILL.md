---
name: chezmoi
description: Guide for managing dotfiles with chezmoi. Covers source state, apply, file naming conventions (dot_, private_, executable_), adding files, ignoring files, templates, and common workflows. Use when the user says 'chezmoi that', 'chezmoi it', 'chezmoi push', 'chezmoi pull', 'add to chezmoi', or asks about dotfile management.
---

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
3. **Scan for changes**: `chezmoi diff` (target changes) and `git diff HEAD` (source changes)
4. **Check for unmanaged files**: `chezmoi unmanaged` — these are files on disk that aren't tracked
5. **Check for secrets in new files**: `chezmoi add --secrets warning` or manually review
6. **Challenge about public repo**: ask if any new files contain secrets, tokens, or private data
7. **Stage, commit, push**: `git add -A && git commit -m "message" && git push`
8. **Verify**: `git status` should be clean

## Pulling chezmoi

When the user asks to pull chezmoi/dotfiles or set up a new machine:

1. **cd to source dir**: `cd ~/.local/share/chezmoi`
2. **Pull**: `git pull --rebase`
3. **Apply**: `chezmoi apply` — this writes all source files to their target locations
4. **Verify**: `chezmoi diff` should be empty (no pending changes)
5. **Run onapply scripts**: any `onapply_` scripts run automatically during `chezmoi apply`
6. **Check for errors**: `chezmoi status` and review any warnings

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

### paru-packages.txt (if applicable)

Same pattern — edit the file, re-add, commit, push.

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
