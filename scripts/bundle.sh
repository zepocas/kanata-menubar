#!/usr/bin/env bash
# Builds KanataMenubar.app from the SwiftPM executable (no Xcode needed).
set -euo pipefail
cd "$(dirname "$0")/.."

CONFIGURATION="${CONFIGURATION:-release}"
APP="build/KanataMenubar.app"

swift build -c "$CONFIGURATION"
BIN_DIR="$(swift build -c "$CONFIGURATION" --show-bin-path)"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_DIR/KanataMenubar" "$APP/Contents/MacOS/KanataMenubar"
cp Resources/Info.plist "$APP/Contents/Info.plist"
cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"

# VERSION is set by the release workflow from the pushed tag (e.g. "v0.1.0" -> "0.1.0").
# Local builds fall back to the current tag, if any, or stay at the Info.plist default.
VERSION="${VERSION:-}"
VERSION="${VERSION#v}"
if [[ -z "$VERSION" ]]; then
    VERSION="$(git describe --tags --exact-match 2>/dev/null | sed 's/^v//')" || true
fi
if [[ -n "$VERSION" ]]; then
    plutil -replace CFBundleShortVersionString -string "$VERSION" "$APP/Contents/Info.plist"
fi

# Ad-hoc signature: enough to run locally on Apple silicon.
codesign --force --sign - --timestamp=none "$APP"

echo "Built $APP"
