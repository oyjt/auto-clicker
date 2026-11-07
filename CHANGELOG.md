# Changelog / 更新日志

User-visible changes are recorded here in English and Simplified Chinese.
Add upcoming changes under `Unreleased`; before publishing, move them into one
`## [X.Y.Z] - YYYY-MM-DD` section containing both languages.
Release tags use `vX.Y.Z`; see [the release guide](docs/RELEASING.md).

这里以英文和简体中文记录面向用户的变更。待发布内容写在 `Unreleased` 下，
发布前归入对应的 `## [X.Y.Z] - YYYY-MM-DD` 章节，同一版本内保留两种语言。
发布标签使用 `vX.Y.Z`，完整步骤见[发版指南](docs/RELEASING.md)。

## [Unreleased]

### English

#### Changed

- Added English and Simplified Chinese entries to the changelog.

### 简体中文

#### 变更

- 更新日志同时提供英文和简体中文内容。

## [1.0.0] - 2026-11-08

### English

#### Added

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

#### Changed

- Focused the English and Chinese READMEs on installation and everyday use,
  with workspace, toolbar and settings previews in both languages.
- Moved build instructions and implementation notes to the development guide.
- Grouped product and design documentation under `docs/` and added repository
  guidance for AI-assisted development in `AGENTS.md`.

### 简体中文

#### 新增

- 原生 macOS 应用，支持最多 50 个编号点击靶点和悬浮操作栏。
- 每个靶点可单独设置左键、右键或双击、点击前延迟、按住时长、重复次数、
  随机位置和随机延迟，支持指定轮数或持续循环。
- 暂停和继续时保留已完成进度，提供独立的“停止并重置”操作。
- 支持全局 Control + Option + Space 快捷键，以及仅在运行期间启用的 Escape 快捷键。
- 支持多显示器定位、记住操作栏位置，并在本机保存设置。
- 支持跟随系统、浅色和深色外观，以及英文和简体中文界面。
- 检查辅助功能权限；休眠、显示器布局改变或权限失效时自动停止。
- 默认英文 README、中文版本及发版流程文档。
- GitHub Release 自动构建通用 macOS DMG、SHA-256 校验文件和对应版本的更新说明。

#### 变更

- 中英文 README 聚焦安装与日常使用，加入两种语言的工作台、悬浮栏和设置页预览。
- 构建步骤和实现说明集中放入开发指南。
- 产品与设计文档整理到 `docs/`，根目录新增 `AGENTS.md`，为 AI 辅助开发提供项目指引。
