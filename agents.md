# Agent Maintenance Instructions

This document instructs AI agents on how to maintain the package management system in this chezmoi repo.

## Package Management Files

| File | Purpose | Managed by |
|------|---------|------------|
| `paru-packages.txt` | Source list of packages for Arch/paru | Human / Agent |
| `install-paru-packages.sh` | Script that reads list and installs missing packages | Agent (update when logic changes) |
| `.chezmoiignore` | Excludes package files from deployment | Agent |

## When to Update `paru-packages.txt`

**Add a package when:**
- User explicitly requests a new tool be installed
- A config file references a binary not in the list
- Setting up a new machine reveals a missing dependency

**Remove a package when:**
- User explicitly requests removal
- Package is replaced by another (note the replacement in commit)
- Package is deprecated/unmaintained

**Format rules:**
- One package per line
- Official repo packages: bare name (e.g., `neovim`)
- AUR packages: bare name (paru handles both)
- Group related packages with `# Category` comments
- Keep alphabetical within categories
- No inline comments on package lines

## When to Update `install-paru-packages.sh`

Update the script when:
- paru/pacman flags change
- Need to support additional package managers (brew, apt, etc.)
- Installation logic needs improvement (parallel, better output, etc.)
- Add dry-run / verbose flags

**Do NOT modify the script just to add/remove packages** — that's what `paru-packages.txt` is for.

## Workflow for Agents

1. **User asks to add package** → Edit `paru-packages.txt`, commit, push
2. **User runs `chezmoi apply`** → Script runs automatically (via `run_onchange_`), installs missing
3. **User asks to remove package** → Edit `paru-packages.txt` (remove line), commit. Note: script doesn't auto-remove; user must `paru -R` manually if desired

## Testing Changes

```bash
# Dry run (show what would be installed)
cd ~/.local/share/chezmoi
./install-paru-packages.sh  # safe to run, only installs missing

# Verify package list syntax
grep -E '^[^#[:space:]]' paru-packages.txt | sort -u
```

## Current Package Categories

- Terminal & shell
- Editors
- Git & GitHub
- Development tools
- Containers & VMs
- Utilities
- Fonts

Keep categories in this order when adding packages.