# configs

My terminal and IDE configuration files, managed with [chezmoi](https://www.chezmoi.io/).

## Quick start (new machine)

```bash
chezmoi init --apply https://github.com/SterlingNerd/configs.git
```

That's it — no config file needed. Chezmoi clones the repo, deploys all dotfiles, and runs the package installer script automatically.

## Daily workflow

```bash
chezmoi diff                    # see local changes vs repo
chezmoi add ~/.config/zed/settings.json  # capture an edit
chezmoi apply                   # deploy changes
chezmoi git add -A && chezmoi git commit && chezmoi git push  # commit & push
```

## What's managed

| Config | Path |
|--------|------|
| Alacritty | `~/.config/alacritty/` |
| Git | `~/.config/git/config` |
| Micro | `~/.config/micro/` |
| Neovim | `~/.config/nvim/` |
| Oh My Posh | `~/.config/oh-my-posh/` |
| Pi Agent | `~/.config/pi/agent/` |
| Zed | `~/.config/zed/settings.json` |

Secret files (`models-store.json`, `zed/settings.json`) are deployed with `0600` permissions.

## Package management (Arch)

A curated package list lives in `shelly-packages.txt`. The `run_onchange_install-shelly-packages.sh` script runs on every `chezmoi apply` and installs any missing packages via `shelly` (standard repos first, then AUR).

To add a package, just add it to `shelly-packages.txt` — it'll be installed on the next apply.

## How chezmoi works

This repo uses chezmoi's default layout: source root maps to `~`, dot-directories use the `dot_` prefix (e.g., `dot_config/` → `~/.config/`). No custom config file needed.

See the [chezmoi docs](https://www.chezmoi.io/reference/cli/) for full details on commands, templates, and advanced features.