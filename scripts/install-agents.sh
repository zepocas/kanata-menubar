#!/usr/bin/env bash
# Installs (or with --uninstall removes) a LaunchAgent that starts Kanata Menubar at login.
# Rendered from launchd/*.plist.in into ~/Library/LaunchAgents.
set -euo pipefail
cd "$(dirname "$0")/.."

LABEL="io.github.zepocas.kanata-menubar"
AGENT_DIR="$HOME/Library/LaunchAgents"
DOMAIN="gui/$(id -u)"
TARGET="$AGENT_DIR/$LABEL.plist"

if [[ "${1:-}" == "--uninstall" ]]; then
    launchctl bootout "$DOMAIN/$LABEL" 2>/dev/null && echo "Unloaded $LABEL" || true
    rm -f "$TARGET"
    echo "Removed $TARGET"
    exit 0
fi

APP="/Applications/KanataMenubar.app"
[[ -d "$APP" ]] || { echo "Missing $APP. Run 'make install' first." >&2; exit 1; }

# Stop a copy started by hand so it doesn't collide with the launchd one.
pkill -x KanataMenubar 2>/dev/null || true

mkdir -p "$AGENT_DIR" "$HOME/Library/Logs"
sed -e "s|@HOME@|$HOME|g" -e "s|@APP@|$APP|g" "launchd/$LABEL.plist.in" > "$TARGET"
plutil -lint -s "$TARGET"
launchctl bootout "$DOMAIN/$LABEL" 2>/dev/null || true
launchctl bootstrap "$DOMAIN" "$TARGET"
echo "Loaded $LABEL"

echo
echo "Done. Kanata Menubar now starts at login."
