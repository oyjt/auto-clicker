#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
export CLANG_MODULE_CACHE_PATH="$PWD/.build/module-cache"
./scripts/build.sh
swiftc -parse-as-library -I .build/release \
  Sources/Clicker/ClickEngine.swift Sources/Clicker/OverlayController.swift \
  Sources/Clicker/MainView.swift Sources/Clicker/PointEditor.swift \
  Sources/Clicker/Preferences.swift Sources/Clicker/ClickerTheme.swift scripts/render-preview.swift \
  .build/release/ClickerCore.build/*.swift.o -o .build/render-preview
.build/render-preview docs/previews
