#!/usr/bin/env bash
# Symlink every dotfile under home/ into $HOME using GNU stow, then place the
# system files that the configs depend on. Idempotent; safe to re-run.
set -euo pipefail
cd "$(dirname "$0")"

if ! command -v stow >/dev/null; then
    echo "GNU stow is required:  sudo pacman -S stow" >&2
    exit 1
fi

# Plain stow of the 'home' package into $HOME. --no-folding keeps shared dirs
# like ~/.config as real directories (only leaf files are symlinked), so other
# apps that write there aren't disturbed.
echo "==> stowing dotfiles into $HOME"
if ! stow --target="$HOME" --restow --no-folding home; then
    cat <<'WARN' >&2

stow reported conflicts: you already have real files where these symlinks go.
On a fresh machine there are none and this just works. To deploy over existing
configs you must resolve them first — either back up and remove the conflicting
files and re-run, or adopt your current files into the repo:

    stow --adopt --target="$HOME" --no-folding home   # moves your files INTO the repo
    git checkout .                                     # then restore repo versions

WARN
    exit 1
fi

echo "==> installing udev rule for the Hyprland multi-GPU DRM symlinks"
sudo install -m 0644 etc/udev/rules.d/99-hypr-gpu.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules
sudo udevadm trigger --subsystem-match=drm --action=add

cat <<'EOF'

Done. Remaining manual steps:
  - Install the stack:       Hyprland, quickshell + Ambxst (axctl), GNU stow,
                             the terminals (kitty/ghostty/alacritty), fish, cava,
                             btop, solaar, plus your GPU driver stack.
  - Reload Ambxst binds:     Super+Alt+B  (or restart the shell)
  - tool-ring (Super+G):     clone it and symlink the launcher, e.g.
        git clone https://github.com/<you>/tool-ring ~/Projects/tool-ring
        ln -s ~/Projects/tool-ring/bin/tool-ring ~/.local/bin/tool-ring

Note: hyprland.conf and ambxst/binds.json are tuned to a specific ASUS laptop
(PCI addresses, monitor names) and assume the username 'nethum'. Adjust before
expecting them to work on different hardware.
EOF
