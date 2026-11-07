# Auto Clicker: AI development guide

Native macOS 13+ utility built with SwiftUI, AppKit and CoreGraphics through
Swift Package Manager. Keep the app local, with no accounts, telemetry or
third-party runtime dependencies.

## Read the relevant context

- [Product requirements](docs/PRODUCT.md): capabilities and behavioral constraints.
- [Design system](docs/DESIGN.md): native UI, visual tokens and interaction details;
  read before changing the interface. Source paths in this guide are relative to
  the repository root.
- [Development guide](docs/DEVELOPING.md): build/test commands and preview rendering.
- [Release guide](docs/RELEASING.md): versioning, packaging and GitHub Releases.

Keep detailed product and design decisions in those guides rather than copying
them into this file. `README.md` is the English user guide; keep
`README.zh-CN.md` aligned when user-facing instructions change.

## Code map

- `Sources/ClickerCore/`: click-plan validation and execution progress.
- `Sources/Clicker/`: app lifecycle, click engine, SwiftUI pages and AppKit overlays.
- `Tests/ClickerCoreTests/` and `Tests/ClickerTests/`: corresponding Swift tests.
- `Resources/`: bundle metadata, localized names and the icon master.
- `scripts/`: app builds, DMG packaging, release notes and offscreen previews.

## Working conventions

- Make the smallest complete change; reuse the existing native controls and helpers.
- Preserve the visible multi-target workflow, permission checks and input validation.
- Preserve pause/resume checkpoints and mouse-button release on cancellation;
  position or click-setting changes invalidate a paused plan.
- Add UI text in both Chinese and English through the existing `engine.t` pattern
  in `Sources/Clicker/Preferences.swift`. Preserve accessibility labels, system
  appearance and Reduce Motion behavior.
- Keep `local.autoclicker.mac` stable unless the task requires a migration;
  changing it can affect saved settings and Accessibility permissions.
- Record user-visible changes under `Unreleased` in [CHANGELOG.md](CHANGELOG.md).
  Keep developer details in `docs/`, not in the user-facing READMEs.

## Verify the change

- For Swift behavior changes, run the relevant Swift tests using the environment
  and commands in the development guide. Add regression coverage for nontrivial bugs.
- For UI changes, run `./scripts/render-preview.sh` and inspect affected previews
  in both languages and appearances. Offscreen previews do not prove global
  shortcuts, live window compositing or mouse delivery work.
- For packaging changes, run the release-note tests and the DMG packaging command
  for a documented version; verify architectures, signature and image integrity.
- For documentation-only changes, check local links and image paths; a full app
  test run is unnecessary.
- Do not send real mouse events to unrelated apps as part of automated checks.
  State any manual interaction checks that remain unverified.
- Keep generated build products, caches and signing credentials out of Git.
