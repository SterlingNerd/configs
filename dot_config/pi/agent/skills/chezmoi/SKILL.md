---
name: chezmoi
description: Guide for managing dotfiles with chezmoi. Covers source state, apply, file naming conventions (dot_, private_, executable_), adding files, ignoring files, templates, and common workflows. Use when the user says 'chezmoi that', 'add to chezmoi', or asks about dotfile management.
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

### Common commands

```bash
chezmoi source-path                    # Show source directory
chezmoi add <path>                     # Add file to source state
chezmoi apply                          # Apply source state to home
chezmoi diff                           # Show pending changes (source vs target)
chezmoi status                         # Show managed files status
chezmoi edit <target-path>             # Edit file in source state
chezmoi managed                        # List all managed targets
chezmoi unmanaged                      # List files not managed by chezmoi
chezmoi init                           # Initialize chezmoi from remote repo
chezmoi update                         # Pull and apply changes from remote
```

### Removing files from chezmoi

**`chezmoi forget <target-path>`** — Remove from chezmoi source state but keep the file on disk. Use this when you want to stop managing a file but keep it as-is.

**`chezmoi destroy <target-path>`** — Remove from chezmoi source state AND delete the target file. Use this when you want to completely remove the file.

## Workflow: "Chezmoi that"

When the user says "chezmoi that" or "add to chezmoi":

1. **Copy** the file(s) into the chezmoi source directory with correct naming
2. **Git add + commit + push** in the source repo
3. Verify with `chezmoi status` or `git status`

### Example: Adding a config file

```bash
# 1. Create destination in source repo
mkdir -p ~/.local/share/chezmoi/dot_config/nvim
cp ~/.config/nvim/init.lua ~/.local/share/chezmoi/dot_config/nvim/init.lua

# 2. Stage and commit
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

### chezmoi-sync

Sync the entire source repo: add, commit, push in one command.

```bash
chezmoi-sync "message"
```

## Templates

Chezmoi supports Go templates for dynamic content. Use `.tmpl` extension:

```bash
# Source file with template
dot_config/git/config.tmpl

# Contains {{ .username }} or other variables
# Rendered on apply using chezmoi data (env vars, command output, etc.)
```

## Troubleshooting

- **"not managed"** — File isn't in the source state. Run `chezmoi add <path>` or check if it's in `.chezmoiignore`
- **"cannot add chezmoi file to chezmoi"** — You're inside the source directory. Use git directly instead of `chezmoi add`
- **File changed since chezmoi last wrote it** — The target was modified externally. Either `chezmoi apply` to overwrite, or `chezmoi edit` to update the source
- **Permission issues** — Check `private_`, `readonly_`, or `executable_` prefixes
- **Template errors** — Check `.tmpl` files for Go template syntax
- **`.chezmoiignore` alone doesn't stop tracking** — If a file is already in source state, you must remove it first (delete from source dir + add to ignore)
- **`chezmoi apply` fails with TTY errors** — May be caused by encrypted files or interactive prompts. Check `chezmoi diff` for details
