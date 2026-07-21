#!/usr/bin/env bash
# run_once_install-paru.sh
# Runs once per machine on first chezmoi apply.
# Reads paru-packages.txt and installs any missing packages via paru.

set -euo pipefail

PACKAGE_FILE="${CHEZMOI_SOURCE_DIR:-$HOME/.local/share/chezmoi}/paru-packages.txt"

if [[ ! -f "$PACKAGE_FILE" ]]; then
    echo "Error: Package file not found at $PACKAGE_FILE" >&2
    exit 1
fi

# Read packages, skip comments and empty lines
mapfile -t PACKAGES < <(grep -E '^[^#[:space:]]' "$PACKAGE_FILE" | sed 's/#.*//' | xargs -n1)

if [[ ${#PACKAGES[@]} -eq 0 ]]; then
    echo "No packages to install."
    exit 0
fi

echo "Checking ${#PACKAGES[@]} packages from $PACKAGE_FILE..."

# Check which are already installed
TO_INSTALL=()
for pkg in "${PACKAGES[@]}"; do
    if pacman -Q "$pkg" &>/dev/null || paru -Q "$pkg" &>/dev/null; then
        echo "  ✓ $pkg (already installed)"
    else
        echo "  + $pkg (will install)"
        TO_INSTALL+=("$pkg")
    fi
done

if [[ ${#TO_INSTALL[@]} -eq 0 ]]; then
    echo "All packages already installed."
    exit 0
fi

echo
echo "Installing ${#TO_INSTALL[@]} packages via paru..."
paru -S --needed --noconfirm "${TO_INSTALL[@]}"

echo
echo "Done!"
