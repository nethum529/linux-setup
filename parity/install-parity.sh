#!/usr/bin/env bash
# 1:1 parity layer on top of install.sh: the Ambxst shell itself (with local
# widgets), the hyprexpo plugin, wallpapers, prebuilt tools, and the axi
# toolchain. Everything install.sh stows is assumed present. Idempotent.
# Run from the repo root:  ./parity/install-parity.sh
set -euo pipefail
cd "$(dirname "$0")"

AMBXST_SRC="$HOME/.local/src/ambxst"
read -r COMMIT < ambxst/UPSTREAM_COMMIT
URL=$(sed -n 2p ambxst/UPSTREAM_COMMIT)

# ------------------------------------------------- Ambxst shell (the big one)
# Pinned upstream + local-changes.patch (tracked mods) + overlay/ (the custom
# widgets: AirPods quick-connect, usage dropdown, wifi/bt/audio/hva indicators).
echo "==> Ambxst @ ${COMMIT:0:8} + local patch + custom widgets"
if [[ ! -d "$AMBXST_SRC/.git" ]]; then
    git clone "$URL" "$AMBXST_SRC"
fi
git -C "$AMBXST_SRC" fetch -q origin
git -C "$AMBXST_SRC" checkout -q "$COMMIT"
# reset tracked files before re-applying so re-runs don't double-apply
git -C "$AMBXST_SRC" checkout -q -- .
git -C "$AMBXST_SRC" apply --whitespace=nowarn "$PWD/ambxst/local-changes.patch"
cp -r ambxst/overlay/. "$AMBXST_SRC/"
# the overlay carries one absolute path; point it at this machine's home
sed -i "s|/home/nethum|$HOME|g" "$AMBXST_SRC/modules/bar/LidAwakeButton.qml"

echo "==> axctl + ambxst launcher into /usr/local/bin"
sudo install -m 0755 ambxst/axctl /usr/local/bin/axctl
sudo tee /usr/local/bin/ambxst >/dev/null <<EOF
#!/usr/bin/env bash
export PATH="$HOME/.local/bin:\$PATH"
export QML2_IMPORT_PATH="$HOME/.local/lib/qml:\$QML2_IMPORT_PATH"
export QML_IMPORT_PATH="\$QML2_IMPORT_PATH"
exec "$AMBXST_SRC/cli.sh" "\$@"
EOF
sudo chmod 0755 /usr/local/bin/ambxst

# Seed the generated runtime config so binds/looks are right on FIRST launch
# (Ambxst regenerates these afterward; never overwrite an existing set).
if [[ ! -f "$HOME/.local/share/ambxst/hyprland.conf" ]]; then
    echo "==> seeding ~/.local/share/ambxst (first launch parity)"
    mkdir -p "$HOME/.local/share/ambxst"
    cp ambxst/seed/* "$HOME/.local/share/ambxst/"
    sed -i "s|/home/nethum|$HOME|g" "$HOME/.local/share/ambxst/"{hyprland.conf,hyprland.lua,axctl.toml}
fi

# ----------------------------------------------------------------- hyprexpo
# Super+Tab is the hyprexpo plugin (sandwichfarm's fork), via hyprpm.
# Needs a running Hyprland session; skip gracefully otherwise.
if hyprctl version &>/dev/null; then
    if ! hyprpm list 2>/dev/null | grep -q hyprexpo; then
        echo "==> installing hyprexpo via hyprpm (builds against your headers)"
        hyprpm update
        hyprpm add https://github.com/sandwichfarm/hyprexpo || true
    fi
    hyprpm enable hyprexpo || true
    hyprpm reload -n || true
else
    echo "WARN: no Hyprland session; after first login run:" >&2
    echo "  hyprpm update && hyprpm add https://github.com/sandwichfarm/hyprexpo && hyprpm enable hyprexpo && hyprpm reload -n" >&2
fi

# --------------------------------------------------------------- wallpapers
# Ambxst draws the wallpaper itself (QML layer) — no swww/hyprpaper daemon.
# State: ~/.cache/ambxst/wallpapers.json (wallPath + currentWall + matugen).
echo "==> wallpapers -> ~/Pictures/Wallpapers"
mkdir -p "$HOME/Pictures/Wallpapers"
cp -n wallpapers/* "$HOME/Pictures/Wallpapers/"
if [[ ! -f "$HOME/.cache/ambxst/wallpapers.json" ]]; then
    echo "==> seeding wallpaper state (laptop default: renwallpaper)"
    mkdir -p "$HOME/.cache/ambxst"
    cat > "$HOME/.cache/ambxst/wallpapers.json" <<EOF
{
    "activeColorPreset": "Catppuccin",
    "currentWall": "$HOME/Pictures/Wallpapers/renwallpaper.jpg",
    "matugenScheme": "scheme-tonal-spot",
    "perScreenWallpapers": {
    },
    "tintEnabled": false,
    "wallPath": "$HOME/Pictures/Wallpapers"
}
EOF
fi

# ------------------------------------------------------------ prebuilt tools
echo "==> herdr, herdmates, teammux, hyprshell -> ~/.local/bin"
install -m 0755 bin/* "$HOME/.local/bin/"

# ------------------------------------------------------------ axi toolchain
echo "==> axi toolchain (local npm prefix + symlinks, codex-axi via pipx)"
mkdir -p "$HOME/.local/lib/axi-bin"
npm install --prefix "$HOME/.local/lib/axi-bin" --no-fund --no-audit \
    gh-axi sqlite-axi npm-axi chrome-devtools-axi lavish-axi
for t in gh-axi sqlite-axi npm-axi chrome-devtools-axi lavish-axi; do
    ln -sf "$HOME/.local/lib/axi-bin/node_modules/.bin/$t" "$HOME/.local/bin/$t"
done
command -v pipx >/dev/null && pipx install --force codex-axi || \
    echo "WARN: pipx missing; skipped codex-axi" >&2

cat <<'EOF'

Parity layer done. Restart Hyprland (or relog) so:
  - the sourced ~/.local/share/ambxst/hyprland.conf takes effect (binds,
    Super+number workspaces, exec-once = ambxst -> bar/dock/widgets)
  - hyprexpo binds Super+Tab
Wallpaper picker: Super+Comma (ambxst run wallpapers).
NOT ported on purpose: the hermes gateway (private venv under ~/.hermes) —
disable its unit on other machines if you copied it.
EOF
