#!/usr/bin/env bash
# Regenerates Resources/AppIcon.icns (built-in macOS tools only, no external assets).
set -euo pipefail
cd "$(dirname "$0")/.."

ICONSET="$(mktemp -d)/AppIcon.iconset"
swift scripts/make-icon.swift "$ICONSET"
iconutil --convert icns --output Resources/AppIcon.icns "$ICONSET"
rm -rf "$(dirname "$ICONSET")"
echo "Wrote Resources/AppIcon.icns"
