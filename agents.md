# Agent Instructions for chezmoi Package Management

This file instructs AI agents (like me) on how to maintain the package installation script and list.

## Files to maintain

| File | Purpose | Trigger |
|------|---------|---------|
| `paru-packages.txt` | Source of truth: list of packages to ensure installed | Edit to add/remove packages |
| `run_onchange_install-paru.sh.tmpl` | Chezmoo template script that runs on package list changes | Auto-runs when `paru-packages.txt` changes |
| `install-paru-packages.sh` | Standalone script for manual execution (`chezmoi execute-script`) | Run manually anytime |

## How the onchange script works

1. `run_onchange_install-paru.sh.tmpl` is a **chezmoi template** (`.tmpl` extension)
2. It embeds the package list from `paru-packages.txt` at template-render time
3. When `paru-packages.txt` changes → template renders differently → chezmoi detects script content changed → runs it on next `apply`
4. The script checks each package with `pacman -Q` / `paru -Q` and installs only missing ones

## Maintenance rules for agents

### When user asks to add/remove packages:
1. Edit `paru-packages.txt` (add/remove lines, keep alphabetical-ish grouping)
2. Commit the change — the onchange script will auto-run on next `chezmoi apply`
3. No need to touch the script files unless logic changes

### When user reports script issues:
1. Check `run_onchange_install-paru.sh.tmpl` for bugs
2. Test locally with `chezmoi execute-template run_onchange_install-paru.sh.tmpl`
3. Fix and commit

### When adding new package categories:
1. Add comment header in `paru-packages.txt` (e.g., `# New category`)
2. List packages below
3. Keep AUR packages commented by default with note

### Version pinning:
- Do NOT pin versions in `paru-packages.txt` (use package names only)
- `paru -S --needed` handles updates
- If specific version needed, add comment: `# package-name (pinned to x.y.z for reason)`

### Security:
- Never add packages from untrusted sources without user confirmation
- AUR packages are built from source — flag any that seem suspicious
- Prefer official repos (`pacman`) over AUR when equivalent exists

## Testing locally

```bash
# Dry-run the template (shows what would run)
chezmoi execute-template run_onchange_install-paru.sh.tmpl

# Manual run of standalone script
chezmoi execute-script install-paru-packages.sh

# Full apply (runs onchange scripts)
chezmoi apply -v
```

## Common commands for agents

```bash
# View current package list
cat ~/.local/share/chezmoi/paru-packages.txt

# Add a package (example)
echo "new-package" >> ~/.local/share/chezmoi/paru-packages.txt

# Remove a package
sed -i '/^new-package$/d' ~/.local/share/chezmoi/paru-packages.txt

# Commit changes
cd ~/.local/share/chezmoi && git add -A && git commit -m "pkg: add new-package"
```

## Notes

- Both scripts are in `.chezmoiignore` — NOT deployed to `~`
- `CHEZMOI_SOURCE_DIR` env var available in scripts (points to `~/.local/share/chezmoi`)
- `paru` must be installed first (bootstrap: `sudo pacman -S --needed base-devel git && git clone https://aur.archlinux.org/paru.git && cd paru && makepkg -si`)
- On fresh Arch install: install `paru` first, then `chezmoi init --apply`, then `chezmoi apply` runs the onchange script