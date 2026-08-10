#!/usr/bin/env bash
# Make Handy (speech-to-text) work out of the box: download the AppImage,
# register it with app search + autostart, and seed the laptop's settings
# (Left-Shift+Z transcribe binding, parakeet model, autostart on).
# Idempotent. Run from the repo root: ./handy/install-handy.sh
set -euo pipefail
cd "$(dirname "$0")"

APP="$HOME/Applications/Handy.AppImage"

# ------------------------------------------------------------- AppImage -----
if [[ ! -x "$APP" ]]; then
    echo "==> downloading latest Handy AppImage (github.com/cjpais/Handy)"
    mkdir -p "$HOME/Applications"
    URL=$(curl -fsSL https://api.github.com/repos/cjpais/Handy/releases/latest \
        | grep -o 'https://[^"]*amd64\.AppImage"' | tr -d '"' | head -1)
    [[ -n "$URL" ]] || { echo "could not resolve Handy release URL" >&2; exit 1; }
    curl -fL -o "$APP.part" "$URL" && mv "$APP.part" "$APP" && chmod +x "$APP"
else
    echo "==> Handy.AppImage already present"
fi

# ------------------------------------- app search + autostart entries -------
# Generated (not stowed) because Exec/Icon need this machine's real $HOME.
echo "==> desktop entries (app search + autostart)"
mkdir -p "$HOME/.local/share/icons" "$HOME/.local/share/applications" "$HOME/.config/autostart"
cp handy.png "$HOME/.local/share/icons/handy.png"
cat > "$HOME/.local/share/applications/handy.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Handy
Comment=Offline speech-to-text dictation
Exec=$APP
Icon=$HOME/.local/share/icons/handy.png
Terminal=false
Categories=Utility;AudioVideo;
StartupWMClass=handy
EOF
cp "$HOME/.local/share/applications/handy.desktop" "$HOME/.config/autostart/Handy.desktop"
if command -v update-desktop-database >/dev/null; then
    update-desktop-database "$HOME/.local/share/applications" || true
fi

# --------------------------------------------------------- seed settings ----
# Laptop settings minus device selections (mic/output/GPU nulled so Handy
# picks this machine's defaults — seeding another machine's mic name is the
# classic "it's not listening" bug). Never overwrite an existing config.
if [[ ! -f "$HOME/.local/share/com.pais.handy/settings_store.json" ]]; then
    echo "==> seeding Handy settings (transcribe = Left-Shift+Z, parakeet model)"
    mkdir -p "$HOME/.local/share/com.pais.handy"
    cp settings_store.json "$HOME/.local/share/com.pais.handy/settings_store.json"
else
    echo "==> Handy settings already exist; not overwriting"
fi

# ------------------------------------------------ indicator heartbeat seed --
# The HvaIndicator bar widget watches $XDG_STATE_HOME/handy-voice/indicator.json
# ({listening, state, ts}; heartbeat, stale after 4 s). The hva service owns and
# rewrites this file at runtime; seeding an IDLE copy just guarantees the widget
# has a well-formed file to parse before the service's first start.
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/handy-voice"
if [[ ! -f "$STATE_DIR/indicator.json" ]]; then
    echo "==> seeding indicator heartbeat file (IDLE)"
    mkdir -p "$STATE_DIR"
    cp indicator.json "$STATE_DIR/indicator.json"
fi

cat <<'EOF'

Handy installed. Remaining reality checks:
  - Launch it once (app search: "Handy", or it autostarts next login). First
    transcription downloads the parakeet model (~600MB) into
    ~/.cache/huggingface — needs network, takes a minute.
  - Transcribe keybind: hold Left-Shift+Z (Handy's own global shortcut, not a
    Hyprland bind). Wake word "mars" needs the hva daemon on top:
    systemctl --user status hva
  - Mic: Handy uses the system default source; check `pactl list sources short`
    if it hears nothing.
EOF
