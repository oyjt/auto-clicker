# Developing Auto Clicker

[User guide](../README.md) · [Release guide](RELEASING.md)

## Requirements and build

Auto Clicker is a native macOS 13+ app built with SwiftUI, AppKit and CoreGraphics,
using Swift Package Manager and no third-party dependencies. Install Xcode at
`/Applications/Xcode.app`, then run from the repository root:

```sh
./scripts/build.sh
```

This creates `build/自动点击器.app` for the host architecture with an ad-hoc signature.
Override `DEVELOPER_DIR` if Xcode is installed elsewhere. The script accepts Swift
build arguments, for example `--arch arm64 --arch x86_64` for a universal binary.
`APP_VERSION` and `APP_BUILD_NUMBER` can override the source plist's versions in
the built app without editing `Resources/Info.plist`.

The bundle identifier is `local.autoclicker.mac`. Preferences and click plans live
in UserDefaults; changing the identifier may affect saved settings and permissions.
English and Simplified Chinese bundle names are in `Resources/*.lproj/InfoPlist.strings`.
Finder's name and system-provided menus follow macOS language settings.

## Tests

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
CLANG_MODULE_CACHE_PATH="$PWD/.build/module-cache" \
swift test --disable-sandbox --cache-path .build/cache \
  --config-path .build/config --security-path .build/security
python3 scripts/test-release-notes.py
```

Swift tests cover plan validation, timing and position bounds, serialization,
duplicate IDs, progress checkpoints, parameter editing, pause/reset behavior,
toolbar placement and visibility icons. Release-note tests cover version selection
and invalid, missing, empty or duplicate changelog entries.

Global hotkeys, actual mouse delivery, multi-display behavior and live window
rendering require manual checks on a Mac. Packaging verifies both architectures,
the app signature and DMG integrity; it does not replace those interaction checks.
See the [release guide](RELEASING.md) for packaging and signing limitations.

## Icons and interface previews

The icon master is `Resources/AppIcon.png`. To regenerate it and the UI previews:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  swift scripts/make-icon.swift Resources/AppIcon.png
./scripts/render-preview.sh
```

`render-preview.sh` builds the app and renders the actual SwiftUI views into
`docs/previews/`, including English and Chinese workspace/settings pages and
floating controls. These are offscreen renders, not full desktop captures;
window chrome, native tab controls and live material compositing may differ.
The renderer does not send mouse clicks. It temporarily changes language and
appearance preferences and restores their previous values when it finishes.

## Runtime details

- Targets use logical screen points (pt), including Retina and multiple displays.
  Random positions stay within the target's screen. Offscreen targets move back
  to the main screen after a display is removed.
- A 50 ms delay plus a 10 ms hold has a theoretical ceiling of about 16.7 single
  clicks per second. Actual delivery depends on scheduling and the target app.
  Double-click mouse events have a 40 ms gap.
- Pause cancels pending waits and releases any pressed mouse button. Resume
  retries an interrupted hold or double-click in full, including its delay.
- Global Escape registration is best effort and exists only while running;
  pause/stop releases it. Control + Option + Space and toolbar/menu actions remain
  available as alternatives.
- The app handles desktop clicks, not phone-style swipe gestures.

## Repository contents

Keep source, tests, scripts, the icon master and documentation previews in Git.
`.gitignore` excludes build products, SwiftPM state, local IDE/agent metadata,
Python caches and signing credentials. Never commit private keys or certificates.

[PRODUCT.md](PRODUCT.md) records product requirements;
[DESIGN.md](DESIGN.md) records visual tokens, native behavior and layout details.
Impeccable can discover both files in `docs/`. Repository-wide AI development
guidance lives in [AGENTS.md](../AGENTS.md) at the root. User-facing README files
link here for implementation details; release procedures live in
[RELEASING.md](RELEASING.md), and version history stays in
[CHANGELOG.md](../CHANGELOG.md).
