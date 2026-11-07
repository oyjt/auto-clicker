#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
export CLANG_MODULE_CACHE_PATH="$PWD/.build/module-cache"
mkdir -p .build/module-cache .build/cache .build/config .build/security
VERSION="${APP_VERSION:-$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Resources/Info.plist)}"
BUILD_NUMBER="${APP_BUILD_NUMBER:-$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' Resources/Info.plist)}"
if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ || ! "$BUILD_NUMBER" =~ ^[1-9][0-9]*$ ]]; then
    echo "Expected APP_VERSION=X.Y.Z and a positive APP_BUILD_NUMBER." >&2
    exit 1
fi
swift build -c release --disable-sandbox --cache-path .build/cache --config-path .build/config --security-path .build/security "$@"
BIN_DIR="$(swift build -c release --show-bin-path "$@")"
APP="build/自动点击器.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" build/AppIcon.iconset
cp "$BIN_DIR/Clicker" "$APP/Contents/MacOS/AutoClicker"
if [ ! -f Resources/AppIcon.png ]; then
    swift scripts/make-icon.swift Resources/AppIcon.png
fi
for pixels in 16 32 128 256 512; do
    sips -z "$pixels" "$pixels" Resources/AppIcon.png --out "build/AppIcon.iconset/icon_${pixels}x${pixels}.png" >/dev/null
    double=$((pixels * 2))
    sips -z "$double" "$double" Resources/AppIcon.png --out "build/AppIcon.iconset/icon_${pixels}x${pixels}@2x.png" >/dev/null
done
python3 scripts/pack-icon.py build/AppIcon.iconset "$APP/Contents/Resources/AppIcon.icns"
cp Resources/Info.plist "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" "$APP/Contents/Info.plist"
for language in zh-Hans en; do
    mkdir -p "$APP/Contents/Resources/$language.lproj"
    cp "Resources/$language.lproj/InfoPlist.strings" "$APP/Contents/Resources/$language.lproj/InfoPlist.strings"
done
codesign --force --sign - --identifier local.autoclicker.mac "$APP"
codesign --verify --strict "$APP"
echo "$PWD/$APP"
