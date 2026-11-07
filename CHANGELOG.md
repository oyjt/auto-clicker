# Changelog

User-visible changes are recorded here. Add upcoming changes under `Unreleased`.
Before publishing, move them into a dated `## [X.Y.Z] - YYYY-MM-DD` section.
Release tags use `vX.Y.Z`; see [the release guide](docs/RELEASING.md).

## [Unreleased]

### Changed

- Focused the English and Chinese READMEs on installation and everyday use,
  with workspace, toolbar and settings previews in both languages.
- Moved build instructions and implementation notes to the development guide.
- Grouped product and design documentation under `docs/` and added repository
  guidance for AI-assisted development in `AGENTS.md`.

## [1.0.0] - 2026-11-07

### Added

- Native macOS app with up to 50 numbered click targets and a floating toolbar.
- Per-target left, right and double clicks, delay, hold duration, repetitions,
  random position and random delay; finite or continuous cycles.
- Pause and resume with progress preservation; separate Stop & reset action.
- Global Control + Option + Space shortcut and runtime-only Escape shortcut.
- Multi-display positioning, remembered toolbar placement and local settings.
- System, Light and Dark appearance; English and Simplified Chinese interface.
- Accessibility permission checks and automatic stop on sleep, display changes
  or permission loss.
- English default README with a Chinese version and documented release process.
- GitHub Release workflow producing a universal macOS DMG, SHA-256 checksum
  and version-specific release notes.
