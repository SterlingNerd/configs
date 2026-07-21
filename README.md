# configs
A repo to store all my terminal and IDE configuration files.

## chezmoi setup

This repo uses [chezmoi](https://www.chezmoi.io/) as its dotfile manager with the default layout convention:

- **Source directory**: `~/.local/share/chezmoi` (cloned from this repo)
- **Target directory**: `~` (home)
- **Config dirs**: stored under `dot_config/` in source → deployed to `~/.config/`
  - `dot_config/alacritty/` → `~/.config/alacritty/`
  - `dot_config/git/` → `~/.config/git/`
  - `dot_config/micro/` → `~/.config/micro/`
  - `dot_config/nvim/` → `~/.config/nvim/`
  - `dot_config/oh-my-posh/` → `~/.config/oh-my-posh/`
  - `dot_config/pi/` → `~/.config/pi/`
  - `dot_config/zed/` → `~/.config/zed/`

### Secret files (0600 permissions)

Files prefixed with `private_` in the source are deployed with `0600` mode:

- `dot_config/pi/agent/private_models-store.json` → `~/.config/pi/agent/models-store.json` (0600)
- `dot_config/zed/private_settings.json` → `~/.config/zed/settings.json` (0600)

### Quick start (new machine)

```bash
chezmoi init --apply https://github.com/SterlingNerd/configs.git
```

No config file needed — uses chezmoi defaults.

### Daily workflow

```bash
chezmoi diff                    # see local changes vs repo
chezmoi add ~/.config/zed/settings.json  # capture an edit
chezmoi apply                   # deploy changes
chezmoi git add -A && chezmoi git commit && chezmoi git push  # commit & push
```

### Repo structure

```
.
├── .chezmoiignore          # excludes README.md from deployment
├── README.md               # this file (not deployed)
└── dot_config/             # maps to ~/.config/
    ├── alacritty/
    ├── git/
    ├── micro/
    ├── nvim/
    ├── oh-my-posh/
    ├── pi/
    │   └── agent/
    │       ├── models.json
    │       ├── private_models-store.json   # 0600
    │       ├── settings.json
    │       └── trust.json
    └── zed/
        └── private_settings.json           # 0600
```

### Notes

- The original `~/.config/.git` was backed up to `~/.config/.git.chezmoi-bak` (reversible)
- `node_modules/` and secrets like `auth.json` are NOT tracked (respecting .gitignore)
- Private files use chezmoi's `private_` attribute to preserve 0600 permissions

### Package management (Arch/paru)

This repo includes a curated package list for Arch Linux using `paru` (AUR helper):

- **`paru-packages.txt`** — list of packages (one per line, `#` comments supported)
- **`install-paru-packages.sh`** — script to install missing packages from the list

**Usage:**

```bash
# From chezmoi source dir
chezmoi execute-script install-paru-packages.sh

# Or directly
~/.local/share/chezmoi/install-paru-packages.sh
```

The script reads `paru-packages.txt`, skips already-installed packages, and installs the rest via `paru -S --needed --noconfirm`.

Both files are in `.chezmoiignore` (not deployed to `~`). Edit `paru-packages.txt` to add/remove packages, then run the script.

> **Tip:** For a fresh Arch install, run this *after* `chezmoi init --apply` to bootstrap your full environment.