#!/usr/bin/env bash
# Install the Firefox look into the default-release profile: moz-mac userChrome
# theme + user.js (dark force, SSD titlebar, compact density, clean newtab,
# vertical tabs). Idempotent; overwrites chrome/ and user.js by design.
# Run from the repo root: ./firefox/install-firefox.sh
set -euo pipefail
cd "$(dirname "$0")"

# Firefox uses ~/.mozilla, or the XDG path when ~/.mozilla never existed.
for base in "$HOME/.config/mozilla/firefox" "$HOME/.mozilla/firefox"; do
    [[ -f "$base/profiles.ini" ]] && BASE="$base" && break
done
if [[ -z "${BASE:-}" ]]; then
    echo "No Firefox profile yet. Launch firefox once, close it, re-run." >&2
    exit 1
fi

PROFILE=$(awk -F= '/^\[/{p=0} /^Name=default-release/{p=1} p&&/^Path=/{print $2; exit}' "$BASE/profiles.ini")
[[ -z "$PROFILE" ]] && PROFILE=$(awk -F= '/^Path=/{print $2; exit}' "$BASE/profiles.ini")
DEST="$BASE/$PROFILE"
[[ -d "$DEST" ]] || { echo "Profile dir $DEST missing" >&2; exit 1; }

echo "==> installing userChrome (moz-mac) + user.js into $DEST"
rm -rf "$DEST/chrome"
cp -r chrome "$DEST/chrome"
cp user.js "$DEST/user.js"

cat <<'EOF'
Done. Restart Firefox. Notes:
  - user.js re-asserts these prefs on every launch; edit the repo copy, not prefs.js.
  - Extensions are NOT synced (uBlock Origin, Multi-Account Containers, and the
    Cupertino theme exist on the source machine but are all currently disabled;
    the look is 100% moz-mac CSS + user.js).
  - Titlebar: user.js sets browser.tabs.inTitlebar=0 so the KWin/Klassy-style
    decorations show; under pure Hyprland there is no SSD titlebar — set it to
    1 there if you want tabs at the very top.
EOF
