# Chezmoi Setup

This machine uses [chezmoi](https://chezmoi.io) to manage dotfiles.

## What it does

Chezmoi maintains a source directory (`~/.local/share/chezmoi`) that defines all your dotfiles. Running `chezmoi apply` writes them to your home directory with correct paths, permissions, and attributes. Everything is tracked in git at `github.com/SterlingNerd/configs`.

## Quick start

```bash
# See what's drifted
chezmoi status

# Apply pending changes
chezmoi apply

# Add a new file
chezmoi add ~/.config/foo/bar

# Re-sync a file you edited manually
chezmoi re-add ~/.config/foo/bar

# Run a full drift review
bash ~/.local/share/chezmoi/dot_config/pi/agent/skills/chezmoi/scripts/chezmoi-review
```

## Package management

System packages are listed in `shelly-packages.txt` and installed via the shelly script on `chezmoi apply`.

Pi extensions are managed via `pi install` — this updates `~/.config/pi/agent/settings.json` which is tracked by chezmoi.

## Safety

**Never run `chezmoi apply --force`** — it overwrites your live dotfiles with the source state, destroying any changes made outside chezmoi. If apply fails, use `chezmoi diff` and `chezmoi-review` to resolve drift first.

## Source repo

- **URL**: https://github.com/SterlingNerd/configs
- **Branch**: main
- **CLI git**: use `chezmoi git <args>` to run git commands in the source directory
