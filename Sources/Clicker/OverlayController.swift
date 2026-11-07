import AppKit
import SwiftUI
import ClickerCore

final class FloatingPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
    init(size: CGSize) {
        super.init(contentRect: CGRect(origin: .zero, size: size), styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        level = .floating
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        hidesOnDeactivate = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isReleasedWhenClosed = false
        animationBehavior = .utilityWindow
    }
}

enum ToolbarLayout {
    static let size = CGSize(width: 284, height: 52)
    static let cornerRadius: CGFloat = 12

    static func origin(saved: [Double]?, screens: [CGRect], preferred: CGRect) -> CGPoint {
        if let saved, saved.count == 2, saved.allSatisfy(\.isFinite) {
            let point = CGPoint(x: saved[0], y: saved[1])
            if screens.contains(where: { $0.contains(CGRect(origin: point, size: size)) }) { return point }
        }
        return CGPoint(x: max(preferred.minX, preferred.midX - size.width / 2),
                       y: max(preferred.minY, preferred.maxY - size.height - 16))
    }
}

@MainActor
final class OverlayController {
    unowned let engine: ClickEngine
    private var control: FloatingPanel?
    private var targets: [UUID: FloatingPanel] = [:]
    private var editor: NSWindow?
    private let defaults: UserDefaults
    private let positionKey = "clicker.toolbar.origin.v1"

    init(engine: ClickEngine, defaults: UserDefaults = .standard) {
        self.engine = engine
        self.defaults = defaults
    }

    private func availableOrigin(saved: [Double]?) -> CGPoint {
        let screens = NSScreen.screens.map(\.visibleFrame)
        let preferred = NSScreen.main?.visibleFrame ?? screens.first ?? CGRect(x: 0, y: 0, width: 1440, height: 900)
        return ToolbarLayout.origin(saved: saved, screens: screens, preferred: preferred)
    }

    func rememberPosition() {
        guard let control else { return }
        let point = availableOrigin(saved: [Double(control.frame.minX), Double(control.frame.minY)])
        control.setFrameOrigin(point)
        defaults.set([Double(point.x), Double(point.y)], forKey: positionKey)
    }

    func resetPosition() {
        defaults.removeObject(forKey: positionKey)
        control?.setFrameOrigin(availableOrigin(saved: nil))
    }

    func show() {
        if control == nil {
            let panel = FloatingPanel(size: ToolbarLayout.size)
            panel.contentView = NSHostingView(rootView: FloatingControls(engine: engine, controller: self))
            panel.setFrameOrigin(availableOrigin(saved: defaults.array(forKey: positionKey) as? [Double]))
            control = panel
        }
        if let control {
            control.alphaValue = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion ? 1 : 0
            control.orderFrontRegardless()
            NSAnimationContext.runAnimationGroup { context in
                context.duration = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion ? 0 : 0.18
                control.animator().alphaValue = 1
            }
        }
        refresh()
    }

    func hide() {
        control?.orderOut(nil)
        targets.values.forEach { $0.orderOut(nil) }
        editor?.close()
    }

    func refresh() {
        if let control {
            control.setFrameOrigin(availableOrigin(saved: [Double(control.frame.minX), Double(control.frame.minY)]))
        }
        if engine.running { editor?.close() }
        let ids = Set(engine.plan.points.map(\.id))
        for id in Array(targets.keys) where !ids.contains(id) {
            targets.removeValue(forKey: id)?.close()
        }
        for (index, point) in engine.plan.points.enumerated() {
            let panel = targets[point.id] ?? FloatingPanel(size: CGSize(width: 64, height: 64))
            if targets[point.id] == nil {
                panel.contentView = TargetView(engine: engine, controller: self, id: point.id, number: index + 1)
                targets[point.id] = panel
            }
            if let view = panel.contentView as? TargetView {
                view.number = index + 1
                view.needsDisplay = true
                view.setAccessibilityLabel(engine.t("点击位置 \(index + 1)，拖动移动，长按编辑", "Target \(index + 1). Drag to move, hold to edit."))
            }
            panel.setFrameOrigin(CGPoint(x: point.x - 32, y: point.y - 32))
            panel.ignoresMouseEvents = engine.running
            if engine.enabled && engine.targetsVisible { panel.orderFrontRegardless() }
            else { panel.orderOut(nil) }
        }
        control?.appearance = NSApp.appearance
        targets.values.forEach { $0.appearance = NSApp.appearance }
        editor?.appearance = NSApp.appearance
        control?.contentView?.needsDisplay = true
    }

    func toggleVisibility() {
        engine.targetsVisible.toggle()
        refresh()
    }

    func coversControl(_ point: CGPoint) -> Bool {
        control.map { $0.isVisible && $0.frame.insetBy(dx: -5, dy: -5).contains(point) } ?? false
    }

    func edit(_ id: UUID) {
        guard !engine.running, let point = engine.plan.points.first(where: { $0.id == id }) else { return }
        engine.selection = id
        editor?.close()
        let window = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 440, height: 440), styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.title = engine.t("点击位置", "Click target") + " \((engine.plan.points.firstIndex(where: { $0.id == id }) ?? 0) + 1)"
        window.isReleasedWhenClosed = false
        window.level = .floating
        window.contentView = NSHostingView(rootView: PointEditor(engine: engine, point: point, close: { [weak window] in window?.close() }))
        window.center()
        editor = window
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    func showSettings() {
        if engine.running { engine.pause() }
        engine.page = "settings"
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "main" || $0.title == "自动点击器" || $0.title == "Auto Clicker" }) {
            window.makeKeyAndOrderFront(nil)
        } else { engine.openMain?() }
    }
}

struct FloatingControls: View {
    @ObservedObject var engine: ClickEngine
    let controller: OverlayController
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hovered: String?

    var body: some View {
        HStack(spacing: 2) {
            WindowDragHandle(label: engine.t("拖动操作栏", "Drag toolbar"), onDragBegan: { engine.pause() }, onDragEnded: { controller.rememberPosition() })
                .overlay {
                    VStack(spacing: 3) {
                        ForEach(0..<3) { _ in
                            HStack(spacing: 3) {
                                Circle().frame(width: 2.5, height: 2.5)
                                Circle().frame(width: 2.5, height: 2.5)
                            }
                        }
                    }
                    .foregroundStyle(engine.running ? ClickerTheme.accent : Color.secondary)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                }
                .frame(width: 24, height: 32).help(engine.t("拖动操作栏，运行时会自动暂停", "Drag toolbar; pauses clicking while you move it"))
            control(engine.runSymbol, engine.runActionTitle, primary: true) { engine.toggleRunning() }
            separator
            control("plus", engine.t("新增点击位置", "Add target")) { engine.addPoint() }.disabled(engine.running || engine.plan.points.count >= 50)
            control("minus", engine.t("删除选中位置", "Remove selected target")) { engine.deletePoint() }.disabled(engine.running || engine.plan.points.count <= 1)
            control(engine.visibilitySymbol, engine.targetsVisible ? engine.t("隐藏点击位置", "Hide targets") : engine.t("显示点击位置", "Show targets")) { controller.toggleVisibility() }
            control("slider.horizontal.3", engine.t("打开设置", "Open settings")) { controller.showSettings() }
            separator
            control("xmark", engine.t("停止并关闭悬浮控制", "Stop and close controls")) { engine.setEnabled(false) }
        }
        .padding(.horizontal, 6)
        .frame(width: ToolbarLayout.size.width - 8, height: ToolbarLayout.size.height - 8)
        .background(engine.running ? ClickerTheme.green.opacity(0.08) : Color.clear, in: RoundedRectangle(cornerRadius: ToolbarLayout.cornerRadius))
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: ToolbarLayout.cornerRadius, style: .continuous))
        .contextMenu {
            Button(engine.t("停止并重置", "Stop & reset")) { engine.stop() }
                .disabled(!engine.running && !engine.paused)
            Divider()
            Button(engine.t("回到顶部居中", "Move to top center")) { controller.resetPosition() }
        }
        .padding(4)
        .tint(ClickerTheme.accent)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.18), value: engine.running)
    }

    private var separator: some View {
        Rectangle().fill(.primary.opacity(0.09)).frame(width: 1, height: 18).padding(.horizontal, 6)
    }

    private func control(_ symbol: String, _ title: String, primary: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol).font(.system(size: primary ? 19 : 14, weight: .medium))
                .frame(width: primary ? 36 : 32, height: 32)
                .foregroundStyle(primary || engine.running ? ClickerTheme.accent : Color.primary.opacity(0.8))
                .background(hovered == symbol ? Color.primary.opacity(0.06) : Color.clear, in: RoundedRectangle(cornerRadius: 7))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain).help(title).accessibilityLabel(title)
        .onHover { hovered = $0 ? symbol : nil }
    }
}

private struct WindowDragHandle: NSViewRepresentable {
    let label: String
    let onDragBegan: () -> Void
    let onDragEnded: () -> Void
    func makeNSView(context: Context) -> DragView {
        let view = DragView()
        view.setAccessibilityElement(true)
        view.setAccessibilityRole(.button)
        return view
    }
    func updateNSView(_ view: DragView, context: Context) {
        view.setAccessibilityLabel(label)
        view.onDragBegan = onDragBegan
        view.onDragEnded = onDragEnded
    }
    final class DragView: NSView {
        var onDragBegan: (() -> Void)?
        var onDragEnded: (() -> Void)?
        private var startMouse = CGPoint.zero
        private var startOrigin = CGPoint.zero
        private var tracking: NSTrackingArea?
        private var dragging = false

        override func updateTrackingAreas() {
            if let tracking { removeTrackingArea(tracking) }
            super.updateTrackingAreas()
            let area = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .cursorUpdate, .activeAlways, .inVisibleRect], owner: self)
            addTrackingArea(area)
            tracking = area
        }
        override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
        override func resetCursorRects() { addCursorRect(bounds, cursor: .openHand) }
        override func cursorUpdate(with event: NSEvent) { (dragging ? NSCursor.closedHand : NSCursor.openHand).set() }
        override func mouseEntered(with event: NSEvent) { cursorUpdate(with: event) }
        override func mouseExited(with event: NSEvent) { if !dragging { NSCursor.arrow.set() } }
        override func mouseDown(with event: NSEvent) {
            guard let window else { return }
            onDragBegan?()
            startMouse = NSEvent.mouseLocation
            startOrigin = window.frame.origin
            dragging = true
            window.disableCursorRects()
            NSCursor.closedHand.push()
        }
        override func mouseDragged(with event: NSEvent) {
            guard dragging else { return }
            let mouse = NSEvent.mouseLocation
            window?.setFrameOrigin(CGPoint(x: startOrigin.x + mouse.x - startMouse.x,
                                           y: startOrigin.y + mouse.y - startMouse.y))
            NSCursor.closedHand.set()
        }
        override func mouseUp(with event: NSEvent) { finishDrag() }
        override func viewWillMove(toWindow newWindow: NSWindow?) {
            if newWindow == nil { finishDrag() }
            super.viewWillMove(toWindow: newWindow)
        }
        private func finishDrag() {
            guard dragging else { return }
            dragging = false
            NSCursor.pop()
            if let window {
                window.enableCursorRects()
                window.invalidateCursorRects(for: self)
                let inside = bounds.contains(convert(window.mouseLocationOutsideOfEventStream, from: nil))
                (inside ? NSCursor.openHand : NSCursor.arrow).set()
            }
            onDragEnded?()
        }
    }
}

@MainActor
final class TargetView: NSView {
    unowned let engine: ClickEngine
    unowned let controller: OverlayController
    let id: UUID
    var number: Int
    private var origin = CGPoint.zero
    private var startMouse = CGPoint.zero
    private var timer: Timer?
    private var moved = false

    init(engine: ClickEngine, controller: OverlayController, id: UUID, number: Int) {
        self.engine = engine; self.controller = controller; self.id = id; self.number = number
        super.init(frame: CGRect(x: 0, y: 0, width: 64, height: 64))
        setAccessibilityElement(true)
        setAccessibilityRole(.button)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func draw(_ dirtyRect: NSRect) {
        let color = engine.running ? ClickerTheme.nsAccent : NSColor.labelColor
        let circle = NSBezierPath(ovalIn: bounds.insetBy(dx: 11, dy: 11))
        (engine.running ? ClickerTheme.nsAccent.withAlphaComponent(0.20) : NSColor.windowBackgroundColor.withAlphaComponent(0.94)).setFill()
        circle.fill()
        color.setStroke(); circle.lineWidth = 1.7; circle.stroke()
        let lines = NSBezierPath()
        for (start, end) in [(CGPoint(x: 32, y: 3), CGPoint(x: 32, y: 16)), (CGPoint(x: 32, y: 48), CGPoint(x: 32, y: 61)), (CGPoint(x: 3, y: 32), CGPoint(x: 16, y: 32)), (CGPoint(x: 48, y: 32), CGPoint(x: 61, y: 32))] {
            lines.move(to: start); lines.line(to: end)
        }
        lines.lineWidth = 1.7; lines.stroke()
        let text = "\(number)" as NSString
        let attributes: [NSAttributedString.Key: Any] = [.font: NSFont.monospacedDigitSystemFont(ofSize: 20, weight: .medium), .foregroundColor: color]
        let size = text.size(withAttributes: attributes)
        text.draw(at: CGPoint(x: (64 - size.width) / 2, y: (64 - size.height) / 2), withAttributes: attributes)
    }
    override func mouseDown(with event: NSEvent) {
        engine.selection = id
        startMouse = NSEvent.mouseLocation
        origin = window?.frame.origin ?? .zero
        moved = false
        if event.clickCount == 2 { controller.edit(id); return }
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.55, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, !self.moved else { return }
                self.controller.edit(self.id)
            }
        }
    }
    override func mouseDragged(with event: NSEvent) {
        let mouse = NSEvent.mouseLocation
        if hypot(mouse.x - startMouse.x, mouse.y - startMouse.y) > 3 { moved = true; timer?.invalidate() }
        guard moved else { return }
        window?.setFrameOrigin(CGPoint(x: origin.x + mouse.x - startMouse.x, y: origin.y + mouse.y - startMouse.y))
    }
    override func mouseUp(with event: NSEvent) {
        timer?.invalidate()
        if moved, let frame = window?.frame { engine.movePoint(id, to: CGPoint(x: frame.midX, y: frame.midY)) }
    }
    override func rightMouseDown(with event: NSEvent) { controller.edit(id) }
    override func accessibilityPerformPress() -> Bool { controller.edit(id); return true }
    override func resetCursorRects() { addCursorRect(bounds, cursor: .crosshair) }
}
