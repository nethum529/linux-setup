#!/usr/bin/env bash
# One-shot install: packages, stowed dotfiles, udev rule, companion repos,
# vendored tools, and user services. Idempotent; safe to re-run.
#
#   ./install.sh              # everything
#   ./install.sh --no-pkgs    # skip the pacman step (configs + tools only)
set -euo pipefail
cd "$(dirname "$0")"

SKIP_PKGS=0
[[ "${1:-}" == "--no-pkgs" ]] && SKIP_PKGS=1

# ---------------------------------------------------------------- packages ---
if [[ $SKIP_PKGS -eq 0 ]]; then
    echo "==> installing core packages (pacman --needed; see packages.txt)"
    grep -vE '^\s*(#|$)' packages.txt | sudo pacman -S --needed --noconfirm - \
        || echo "WARN: some packages failed (AUR/CachyOS-only on plain Arch?) — continuing" >&2
fi

command -v stow >/dev/null || { echo "GNU stow is required: sudo pacman -S stow" >&2; exit 1; }

# ---------------------------------------------------------------- dotfiles ---
# --no-folding keeps shared dirs like ~/.config real; only leaf files symlink.
echo "==> stowing dotfiles into $HOME"
if ! stow --target="$HOME" --restow --no-folding home; then
    cat <<'WARN' >&2

stow reported conflicts: you already have real files where these symlinks go.
Back up and remove the conflicting files and re-run, or adopt yours into the
repo first:

    stow --adopt --target="$HOME" --no-folding home
    git checkout .

WARN
    exit 1
fi

# ------------------------------------------------------------- GPU config ---
# Detects the GPU topology and generates ~/.config/hypr/gpu.conf plus the
# hybrid-only udev rule with THIS machine's PCI addresses (docs/hardware.md).
echo "==> generating GPU config for this machine"
./tools/gen-gpu-conf.sh

# -------------------------------------------------- agentdash (vendored) -----
# The usage indicator lives in tools/agentdash and runs from ~/Projects/agentdash.
echo "==> deploying agentdash (usage indicator)"
mkdir -p "$HOME/Projects"
rsync -a tools/agentdash/ "$HOME/Projects/agentdash/"
systemctl --user daemon-reload
systemctl --user enable --now agentdash.service

# --------------------------------------------------------------- tailscale ---
# NetworkManager writing resolv.conf as a plain file leaves resolved in
# "foreign" mode and breaks MagicDNS (docs/tailscale.md). Same stub nameserver
# either way, so the symlink is a no-op for everything but Tailscale.
if command -v tailscale >/dev/null && systemctl is-active -q systemd-resolved \
   && [[ "$(readlink /etc/resolv.conf)" != /run/systemd/resolve/stub-resolv.conf ]]; then
    echo "==> pointing /etc/resolv.conf at the systemd-resolved stub (MagicDNS fix)"
    sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
    sudo systemctl enable --now tailscaled
    sudo systemctl restart tailscaled
fi

# ----------------------------------------------------- companion repos -------
clone() { # clone <url> <dir> — clone once, otherwise leave the checkout alone
    [[ -d "$2/.git" ]] && { echo "    $2 already cloned"; return 0; }
    git clone "$1" "$2"
}

echo "==> tool-ring (Super+G radial launcher)"
clone https://github.com/nethum529/tool-ring "$HOME/Projects/tool-ring"
mkdir -p "$HOME/.local/bin"
ln -sf "$HOME/Projects/tool-ring/bin/tool-ring" "$HOME/.local/bin/tool-ring"

echo "==> handy-voice-activation (wake-word daemon)"
clone https://github.com/nethum529/handy-voice-activation "$HOME/handy-voice-activation"
# Its installer builds the venv, places ~/.local/bin/hva, and enables hva.service.
( cd "$HOME/handy-voice-activation" && ./install.sh )

cat <<'EOF'

Done. Remaining manual steps:
  - Handy (speech-to-text app hva toggles): download the AppImage from
    https://handy.computer to ~/Applications/Handy.AppImage and mark executable;
    autostart entry is already stowed.
  - Claude Code CLI:            npm install -g @anthropic-ai/claude-code
  - Log in once to Claude Code so agentdash can read usage credentials.
  - Tailscale:                  sudo tailscale up   (prints the auth link)
  - Reload Ambxst binds:        Super+Alt+B  (or restart the shell)
  - Monitors: hypr/monitors.conf ships this machine's layout; run nwg-displays
    to redo it for different hardware.

Note: GPU env + udev rule are auto-generated for this machine's hardware
(re-run tools/gen-gpu-conf.sh after GPU changes). monitors.conf ships the
source laptop's layout — run nwg-displays to redo it. Remaining assumptions
(username 'nethum', ASUS tools) are listed in docs/hardware.md.
EOF
