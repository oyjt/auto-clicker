#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
VERSION="${1:?Usage: $0 X.Y.Z}"
# Validate before using the version in output paths.
RELEASE_NOTES="$(python3 scripts/release-notes.py "$VERSION")"
mkdir -p build
NOTES="build/AutoClicker-$VERSION-release-notes.md"
printf '%s\n' "$RELEASE_NOTES" > "$NOTES"
APP_VERSION="$VERSION" ./scripts/build.sh --arch arm64 --arch x86_64
APP="build/自动点击器.app"
lipo "$APP/Contents/MacOS/AutoClicker" -verify_arch arm64 x86_64

STAGING="$(mktemp -d "$PWD/build/dmg.XXXXXX")"
trap 'rm -rf "$STAGING"' EXIT
ditto "$APP" "$STAGING/自动点击器.app"
ln -s /Applications "$STAGING/Applications"
DMG="build/AutoClicker-$VERSION-universal.dmg"
hdiutil create -volname "Auto Clicker $VERSION" -srcfolder "$STAGING" \
    -format UDZO -ov "$DMG"
hdiutil verify "$DMG"
(
    cd build
    shasum -a 256 "$(basename "$DMG")" > "$(basename "$DMG").sha256"
)
echo "$PWD/$DMG"
