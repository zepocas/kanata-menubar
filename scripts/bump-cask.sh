#!/usr/bin/env bash
# Updates the kanata-menubar cask in zepocas/homebrew-tap to a released version.
# Usage: scripts/bump-cask.sh [version]   (defaults to the latest GitHub release)
#
# Only edits the cask file locally; review the diff and commit/push it yourself.
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="${1:-}"
if [[ -z "$VERSION" ]]; then
    VERSION="$(gh release list --repo zepocas/kanata-menubar --limit 1 --json tagName --jq '.[0].tagName')"
fi
VERSION="${VERSION#v}"
TAG="v$VERSION"

TAP_DIR="${TAP_DIR:-../homebrew-tap}"
CASK="$TAP_DIR/Casks/kanata-menubar.rb"
[[ -f "$CASK" ]] || { echo "Can't find $CASK (set TAP_DIR to your homebrew-tap checkout)." >&2; exit 1; }

URL="https://github.com/zepocas/kanata-menubar/releases/download/$TAG/KanataMenubar.app.zip"
echo "Downloading $URL to compute its checksum..."
SHA256="$(curl -fsSL "$URL" | shasum -a 256 | cut -d' ' -f1)"

sed -i '' \
    -e "s/^  version \".*\"/  version \"$VERSION\"/" \
    -e "s/^  sha256 \".*\"/  sha256 \"$SHA256\"/" \
    "$CASK"

echo
git -C "$TAP_DIR" --no-pager diff -- "Casks/kanata-menubar.rb"
echo
echo "Updated $CASK to $VERSION. Review the diff above, then:"
echo "  git -C \"$TAP_DIR\" commit -am \"kanata-menubar $VERSION\" && git -C \"$TAP_DIR\" push"
