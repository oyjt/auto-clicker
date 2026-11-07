import AppKit
import ApplicationServices
import ClickerCore
import SwiftUI

@MainActor
final class ClickEngine: ObservableObject {
    @Published var appearance = AppearanceMode(rawValue: UserDefaults.standard.string(forKey: "appearance") ?? "system") ?? .system {
        didSet { UserDefaults.standard.set(appearance.rawValue, forKey: "appearance"); applyAppearance() }
    }
    @Published var language = AppLanguage(rawValue: UserDefaults.standard.string(forKey: "language") ?? "system") ?? .system {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: "language"); overlays?.refresh() }
    }
    @Published var page = "workspace"
    @Published var plan: ClickPlan
    @Published var enabled = false
    @Published var running = false {
        didSet { if running != oldValue { onRunningChanged?(running) } }
    }
    @Published var paused = false
    @Published var globalEscapeAvailable = false
    @Published var targetsVisible = true
    @Published var completedClicks = 0
    @Published var completedCycles = 0
    @Published var trusted = AXIsProcessTrusted()
    @Published var message: String?
    @Published var selection: UUID?
    var onRunningChanged: ((Bool) -> Void)?
    var openMain: (() -> Void)?
    var overlays: OverlayController?
    private var progress = ClickProgress()
    private var activePlan: ClickPlan?
    private var task: Task<Void, Never>?
    private var pressed: (CGPoint, CGMouseButton)?
    private var permissionTimer: Timer?
    private let defaults: UserDefaults
    private let storageKey = "clicker.plan.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: storageKey),
           let stored = try? JSONDecoder().decode(ClickPlan.self, from: data), stored.isValid {
            plan = stored
        } else {
            plan = ClickPlan()
            let frame = NSScreen.main?.visibleFrame ?? CGRect(x: 0, y: 0, width: 1440, height: 900)
            plan.points = [ClickPoint(x: frame.midX, y: frame.midY)]
        }
        selection = plan.points.first?.id
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.trusted = AXIsProcessTrusted()
                if self.running && !self.trusted { self.stop() }
            }
        }
        NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.willSleepNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor [weak self] in self?.stop() }
        }
        NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.stop()
                self?.keepPointsOnScreen()
                self?.overlays?.refresh()
            }
        }
    }

    func save() {
        guard plan.isValid else { message = t("参数超出范围，请检查后再保存。", "Some values are out of range. Check your settings."); return }
        if paused && activePlan != plan { stop() }
        do { defaults.set(try JSONEncoder().encode(plan), forKey: storageKey) }
        catch { message = t("设置保存失败：", "Could not save settings: ") + error.localizedDescription }
    }

    func requestPermission() {
        AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary)
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    func setEnabled(_ value: Bool) {
        if !value { stop() }
        enabled = value
        if value { keepPointsOnScreen(); overlays?.show() }
        else { overlays?.hide() }
    }

    func addPoint() {
        guard !running, plan.points.count < 50 else { return }
        let frame = NSScreen.main?.visibleFrame ?? .zero
        var point = ClickPoint(x: frame.midX + Double(plan.points.count % 5) * 65, y: frame.midY)
        point.delay = plan.defaultDelay
        point.hold = plan.defaultHold
        point.radius = plan.defaultRadius
        plan.points.append(point)
        selection = point.id
        save()
        overlays?.refresh()
    }

    func deletePoint(_ id: UUID? = nil) {
        guard !running, plan.points.count > 1 else { return }
        let target = id ?? selection ?? plan.points.last!.id
        plan.points.removeAll { $0.id == target }
        selection = plan.points.last?.id
        save()
        overlays?.refresh()
    }

    func updatePoint(_ point: ClickPoint) {
        guard !running, point.isValid, let index = plan.points.firstIndex(where: { $0.id == point.id }) else { return }
        var updated = point
        // Parameter edits must not undo a target dragged while its editor was open.
        updated.x = plan.points[index].x
        updated.y = plan.points[index].y
        plan.points[index] = updated
        save()
        overlays?.refresh()
    }

    func movePoint(_ id: UUID, to point: CGPoint) {
        guard !running, let index = plan.points.firstIndex(where: { $0.id == id }) else { return }
        plan.points[index].x = point.x
        plan.points[index].y = point.y
        selection = id
        save()
    }

    func keepPointsOnScreen() {
        let screens = NSScreen.screens.map(\.visibleFrame)
        guard let main = screens.first else { return }
        for index in plan.points.indices {
            let point = CGPoint(x: plan.points[index].x, y: plan.points[index].y)
            if !screens.contains(where: { $0.insetBy(dx: 24, dy: 24).contains(point) }) {
                plan.points[index].x = main.midX
                plan.points[index].y = main.midY
            }
        }
        save()
    }

    var runActionTitle: String {
        running ? t("暂停", "Pause") : (paused ? t("继续", "Resume") : t("开始点击", "Start clicking"))
    }
    var runSymbol: String { running ? "pause.fill" : "play.fill" }
    var statusTitle: String {
        running ? t("正在点击", "Clicking") : (paused ? t("已暂停", "Paused") : (enabled ? t("准备就绪", "Ready") : t("未启动", "Inactive")))
    }
    var visibilitySymbol: String { targetsVisible ? "eye.slash" : "eye" }

    func toggleRunning() { running ? pause() : start() }

    func pause() {
        guard running else { return }
        cancelPendingClick()
        running = false
        paused = true
        overlays?.refresh()
    }

    func start() {
        guard !running else { return }
        trusted = AXIsProcessTrusted()
        guard trusted else { message = t("请先在系统设置中允许“自动点击器”使用辅助功能。", "Allow Auto Clicker in System Settings → Privacy & Security → Accessibility first."); return }
        guard plan.isValid else { message = t("点击参数无效，请检查各项数值。", "Invalid click settings. Check the values before starting."); return }
        if !enabled { setEnabled(true) }
        keepPointsOnScreen()
        if !paused || activePlan != plan {
            progress = ClickProgress()
            completedClicks = 0
            completedCycles = 0
        }
        activePlan = plan
        let snapshot = plan
        paused = false
        running = true
        overlays?.refresh()
        task = Task { [weak self] in
            guard let self else { return }
            do {
                // Allow the play-button mouse-up to finish before posting events.
                try await Task.sleep(nanoseconds: 250_000_000)
                while !Task.isCancelled {
                    let point = snapshot.points[self.progress.pointIndex]
                    try await self.wait(point.waitingTime(randomUnit: Double.random(in: -1...1)))
                    try Task.checkCancellation()
                    let location = point.location(angle: Double.random(in: 0...(2 * .pi)), unitRadius: Double.random(in: 0...1))
                    let screenHeight = NSScreen.screens.first?.frame.maxY ?? 0
                    guard let screen = NSScreen.screens.first(where: { $0.frame.contains(CGPoint(x: point.x, y: point.y)) }) else {
                        throw NSError(domain: "Clicker", code: 2, userInfo: [NSLocalizedDescriptionKey: self.t("找不到点击位置所在的屏幕，请重新摆放位置。", "The target screen is unavailable. Reposition the target.")])
                    }
                    let safe = CGPoint(x: min(screen.frame.maxX - 1, max(screen.frame.minX, location.x)), y: min(screen.frame.maxY - 1, max(screen.frame.minY, location.y)))
                    let quartz = CGPoint(x: safe.x, y: screenHeight - safe.y)
                    // Never send synthetic clicks to the floating controls.
                    let blocked = self.overlays?.coversControl(safe) == true
                    if !blocked {
                        let button: CGMouseButton = point.kind == .right ? .right : .left
                        for click in 1...(point.kind == .double ? 2 : 1) {
                            try Task.checkCancellation()
                            try self.post(down: true, at: quartz, button: button, count: click)
                            self.pressed = (quartz, button)
                            try await self.wait(point.hold / 1000)
                            try self.post(down: false, at: quartz, button: button, count: click)
                            self.pressed = nil
                            if point.kind == .double && click == 1 { try await self.wait(0.04) }
                        }
                        self.completedClicks += 1
                    }
                    let finished = self.progress.advance(in: snapshot)
                    self.completedCycles = self.progress.completedCycles
                    if finished { break }
                }
            } catch is CancellationError {
            } catch { self.message = error.localizedDescription }
            // A cancelled older task must not stop a newly started run.
            if !Task.isCancelled { self.finishRun() }
        }
    }

    private func wait(_ seconds: Double) async throws {
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }

    private func post(down: Bool, at location: CGPoint, button: CGMouseButton, count: Int = 1) throws {
        let type: CGEventType = button == .right ? (down ? .rightMouseDown : .rightMouseUp) : (down ? .leftMouseDown : .leftMouseUp)
        guard let event = CGEvent(mouseEventSource: nil, mouseType: type, mouseCursorPosition: location, mouseButton: button) else {
            throw NSError(domain: "Clicker", code: 1, userInfo: [NSLocalizedDescriptionKey: t("无法创建鼠标事件，已停止执行。", "Could not create a mouse event. Clicking has stopped.")])
        }
        event.setIntegerValueField(.mouseEventClickState, value: Int64(count))
        event.post(tap: .cghidEventTap)
    }

    private func cancelPendingClick() {
        task?.cancel()
        task = nil
        if let (location, button) = pressed { try? post(down: false, at: location, button: button) }
        pressed = nil
    }

    private func finishRun() {
        cancelPendingClick()
        running = false
        paused = false
        activePlan = nil
        progress = ClickProgress()
        overlays?.refresh()
    }

    func stop() {
        finishRun()
        completedClicks = 0
        completedCycles = 0
    }
}
