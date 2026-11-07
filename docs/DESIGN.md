---
name: 自动点击器 / Auto Clicker
description: A quiet native macOS utility for placing, pausing and running numbered click targets.
colors:
  wechat-green: "#07C160"
  light-glyph-green: "#037D3E"
typography:
  heading:
    fontFamily: "-apple-system"
    fontSize: "24pt"
    fontWeight: 600
  section-title:
    fontFamily: "-apple-system"
    fontSize: "14pt"
    fontWeight: 600
  body:
    fontFamily: "-apple-system"
    fontSize: "13pt"
  supporting:
    fontFamily: "-apple-system"
    fontSize: "11pt"
rounded:
  navigation: "7pt"
  toolbar-hover: "7pt"
  target-list: "12pt"
  workspace-card: "14pt"
  floating-toolbar: "12pt"
spacing:
  compact: "8pt"
  editor-inset: "16pt"
  card-inset: "22pt"
  section: "24pt"
  page-stack: "28pt"
  page-inset: "32pt"
---

# Design System: 自动点击器 / Auto Clicker

## Overview

**Creative North Star: "A quiet Mac utility"**

The built interface follows macOS: a material sidebar, grouped settings, system controls and SF Symbols. Its hierarchy keeps configuration in the main window and execution in a compact floating toolbar with numbered desktop targets. This is a description of the implementation, not an approved visual comp.

The app name is 自动点击器 in Chinese and Auto Clicker in English. Appearance supports System, Light and Dark; language supports System default, 简体中文 and English. Both default to the system, persist locally and update the interface immediately. System language uses Chinese when the preferred language starts with `zh`, otherwise English.

**Key Characteristics:**
- Native system typography, semantic colors and regular material.
- WeChat green with readable adaptive glyphs and plain toolbar icons.
- Restrained state transitions that respect Reduce Motion.
- Dense grouped forms within a spacious, scrollable configuration window.

## Colors

The green values in frontmatter come from `ClickerTheme.swift`; neutral surfaces remain dynamic macOS colors.

### Primary
- **WeChat Green** (`wechat-green`): brand surfaces, the main run action and running toolbar wash. Selected navigation uses 12% opacity; list badges use 9% at rest and 20% while running. The main run action has dark green foreground text.
- **Adaptive Glyph Green**: `light-glyph-green` in Light and `wechat-green` in Dark. Use for thin symbols, selected navigation text, target numbers and crosshairs. Running tints every toolbar glyph, including the drag icon, and adds an 8% brand-green wash to the whole toolbar. Desktop target fill uses adaptive green at 20% opacity.

### Neutral
- **Window Background** (`NSColor.windowBackgroundColor`): main content and idle desktop targets, at 94% opacity on targets.
- **Control Background** (`NSColor.controlBackgroundColor`): workspace card and target list.
- **Primary / Secondary**: labels and supporting information; inactive and ready status dots use secondary at 50% opacity. Toolbar icons use primary at 80% when idle, apart from the adaptive green run action. Hover adds a 6% neutral fill.

### Status
- Orange identifies paused progress and missing permission; red identifies invalid values. Accessibility allowed uses the system green. Running has green feedback plus explicit text and a Pause symbol; paused has orange feedback plus Resume text.

**The Plain Toolbar Rule.** Toolbar symbols have no independent colored backgrounds. Preserve the neutral hover treatment and subtle whole-toolbar running wash.

## Typography

Use SwiftUI `.system`, AppKit system fonts and native control typography. The font resolves through macOS, including Chinese glyphs; no external typeface is loaded.

Page headings use the heading token; the target-list title uses section-title; body and supporting tokens cover navigation, labels and details. The run-state title is 18pt semibold. The source also uses 10pt sidebar support, 12pt descriptions, 13pt medium row labels and rounded 15pt target-list numerals. Desktop target numbers are 20pt medium monospaced digits. Coordinates and the shortcut use monospaced type; counters use monospaced digits. Preserve native Form and caption styles rather than forcing every control onto a custom scale.

Allow translated explanatory text to wrap vertically. Keep labels and number/unit relationships legible in both languages.

## Layout

The main scene requests 1000 × 710pt and a unified toolbar; content requires at least 880 × 650pt. A fixed 184pt sidebar sits beside a divider. The main column has an outer ScrollView with page insets, a centered content container capped at 850pt, and a fixed 44pt bottom status bar. Section spacing is generally 24–28pt; the workspace stack uses 26pt. More target rows extend the page vertically.

Click settings and App settings use grouped Forms with inner scrolling disabled and reserved heights of 570pt and 520pt respectively. Their outer page scroll handles overflow, including the action row below Click settings. Preserve this single page scroll model rather than clipping content to the window height.

The horizontal floating control panel is 284 × 52pt with a 276 × 44pt material surface and 12pt corners. It starts centered 16pt below the menu bar, using the screen's visible frame. The run control is 36 × 32pt; secondary buttons are 32 × 32pt; the left six-dot drag handle is 24 × 32pt. The last dragged origin persists locally and is restored only when the entire panel fits a connected visible frame. Invalid or offscreen positions fall back to top center. Each desktop target has a 64 × 64pt panel. The editor is a fixed 440 × 440pt content window with General / Advanced tabs, grouped forms and a separate footer. It is a native desktop layout, with no mobile breakpoints or responsive web grid.

## Elevation & Depth

Regular material distinguishes the sidebar and floating toolbar. The toolbar uses a continuous rounded material boundary with no added border. Workspace surfaces rely on semantic background contrast and dividers rather than custom shadows. Floating panels explicitly disable their window shadows, remain above normal windows, do not activate the app and can join Spaces/full-screen contexts. The editor uses a titled, closable floating NSWindow.

Source declares these materials and window affordances; offscreen content captures do not verify live vibrancy, traffic lights, unified titlebar, tab chrome or compositing against another app.

## Shapes

Use the frontmatter's local radii for custom navigation, toolbar hover surfaces, target lists, workspace cards and floating toolbar. Keep native buttons, fields, segmented controls and grouped form boundaries under macOS control. Target-list badges are circular; desktop targets are crosshairs with a centered circular boundary and number. SF Symbols provide control imagery. The bundled icon (`Resources/AppIcon.png`) is a single-color green cursor within an open circular ring, on a matte light gray-white squircle; the sidebar displays this same asset. The default icon uses the readable light glyph green (#037D3E), a fixed light gray-white tile and a softer outer shadow. The 1024px master uses a 32px ring, a shorter cursor tail and a combined optical offset of +12px horizontally / -12px vertically. Preserve its reference-led flat mark, rounded ring endpoints and clear gap around the cursor; do not add crosshair ticks or decorative highlights.

## Components

- **Navigation:** three plain sidebar buttons with SF Symbols; the active row uses translucent green with adaptive green text. The keyboard reminder stays at the sidebar bottom.
- **Workspace:** a concise heading and Show controls action; when controls are open, this becomes Close controls, or Close & reset while running/paused. Its help explicitly says closing stops and clears progress. The run card separates Start / Pause / Resume from Stop & reset, with state text and target/cycle summary. Permission guidance remains visible when needed.
- **Multi-target list:** preserve the current visible target list, Add target and row edit/remove actions. Do not collapse or remove multi-target entry. Rows retain click summaries and coordinates; modifications disable while running, with at least one and at most 50 targets.
- **Native forms:** right-aligned numeric fields with units, system pickers and grouped sections. Appearance uses a segmented picker; language uses a native picker. Focus, disabled and keyboard behavior comes from SwiftUI/AppKit.
- **Floating controls:** left six-dot grip, Start / Pause / Resume, add/remove, visibility, settings and close. Stop & reset lives in the context menu, main window and menu bar; the context menu also resets toolbar placement to top center. All icon buttons expose help and accessibility labels. The grip is drawn in SwiftUI over an AppKit view that handles mouse-down/drag/up events. Hover shows an open hand, dragging shows a closed hand, release restores the appropriate cursor and saves the position. Starting a drag pauses clicking without resuming automatically. The eye expresses the next action: `eye.slash` hides visible targets; `eye` shows hidden targets. Hiding preserves execution. Opening settings pauses; closing controls stops and resets.
- **Desktop targets and editor:** drag to position; hold for 550ms, double-click or right-click to edit. Targets pass mouse events through while running. The editor retains native Cancel/Save shortcuts and invalid-range feedback. Changing the plan invalidates a paused checkpoint; appearance, language and visibility changes preserve it.
- **Progress and menus:** pause cancels pending waits and releases a pressed mouse button, preserving completed clicks and the sequence checkpoint. Resume retries an interrupted operation with its delay; Stop & reset clears counts. The menu bar exposes the same run action and separate reset. ⌃⌥Space starts / pauses / resumes globally. Runtime-only Carbon Esc registration stops and resets while running and is released on pause/stop; registration is best effort. Show the status-bar Esc hint only when available; retain ⌃⌥Space and toolbar/menu controls as fallbacks. ⌘, opens settings.

Motion uses 200ms ease-out for target-row state and 180ms ease-out for toolbar running tint, plus a 180ms toolbar reveal fade. Reduce Motion removes these custom transitions and fade. AppKit-drawn targets redraw immediately; no continuous pulse or animated target movement is implemented.

## Do's and Don'ts

### Do:
- Do retain semantic system colors, regular material and native control feedback in both appearances.
- Do keep English and Chinese text readable, with wrapping and page scrolling where provided.
- Do distinguish green running / Pause from orange paused / Resume, with Stop & reset available in the context menu, main window and menu bar.
- Do preserve Reduce Motion behavior, icon accessibility labels and visible multi-target entry.

### Don't:
- Don't replace native grouped forms or window behavior with a web dashboard or phone overlay.
- Don't hard-code screenshot colors as replacements for dynamic macOS colors.
- Don't describe offscreen previews as verification of live window chrome, tab chrome or material composition.

Evidence: `Sources/Clicker/ClickerTheme.swift`, `MainView.swift`, `PointEditor.swift`, `OverlayController.swift`, `Preferences.swift`, `ClickEngine.swift` and `AutoClickerApp.swift`; offscreen previews `docs/previews/workspace-light-zh.png`, `workspace-dark-en.png`, `workspace-paused-zh.png`, `toolbar-ready.png` and `toolbar-running.png`. The local native desktop service is unavailable; live shortcuts, mouse delivery and material compositing remain unverified. No approved comp exists, and web-only design detectors do not apply to this native application. The sidecar records native metadata; it supplies no fabricated HTML/CSS replicas of AppKit controls.
