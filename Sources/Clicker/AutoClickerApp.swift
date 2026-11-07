import AppKit
import Carbon
import SwiftUI

@main
struct AutoClickerApp: App {
    @StateObject private var engine = ClickEngine()
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        Window(engine.appName, id: "main") {
            MainView(engine: engine)
                .onAppear { delegate.configure(engine) }
                .onExitCommand { engine.stop() }
        }
        .defaultSize(width: 1000, height: 710)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(replacing: .appSettings) {
                Button(engine.t("设置…", "Settings…")) {
                    engine.overlays?.showSettings()
                }.keyboardShortcut(",", modifiers: .command)
            }
            CommandMenu(engine.t("点击控制", "Click Controls")) {
                Button(engine.enabled ? engine.t("关闭悬浮控制", "Close floating controls") : engine.t("启动悬浮控制", "Show floating controls")) { engine.setEnabled(!engine.enabled) }
                    .keyboardShortcut("o", modifiers: [.command, .shift])
                Button(engine.runActionTitle) { engine.toggleRunning() }
                Button(engine.t("停止并重置", "Stop & reset")) { engine.stop() }.disabled(!engine.running && !engine.paused)
                Divider()
                Button(engine.t("新增点击位置", "Add target")) { engine.addPoint() }.disabled(engine.running || engine.plan.points.count >= 50)
                Button(engine.targetsVisible ? engine.t("隐藏点击位置", "Hide targets") : engine.t("显示点击位置", "Show targets")) { engine.overlays?.toggleVisibility() }
            }
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var engine: ClickEngine?
    private var escapeHotkey: EventHotKeyRef?
    private var hotkey: EventHotKeyRef?
    private var handler: EventHandlerRef?
    private var statusItem: NSStatusItem?

    func configure(_ engine: ClickEngine) {
        guard self.engine == nil else { return }
        self.engine = engine
        engine.overlays = OverlayController(engine: engine)
        engine.applyAppearance()
        NSApp.windows.first(where: { $0.isVisible && !($0 is NSPanel) })?.identifier = NSUserInterfaceItemIdentifier("main")
        var type = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let installed = InstallEventHandler(GetApplicationEventTarget(), { _, event, context in
            guard let context else { return OSStatus(eventNotHandledErr) }
            let delegate = Unmanaged<AppDelegate>.fromOpaque(context).takeUnretainedValue()
            var hotkeyID = EventHotKeyID(signature: 0, id: 0)
            guard let event = event else { return OSStatus(eventNotHandledErr) }
            guard GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &hotkeyID) == noErr else { return OSStatus(eventNotHandledErr) }
            let identifier = hotkeyID.id
            Task { @MainActor in
                if identifier == 2 { delegate.engine?.stop() }
                else { delegate.engine?.toggleRunning() }
            }
            return noErr
        }, 1, &type, Unmanaged.passUnretained(self).toOpaque(), &handler)
        let registered = RegisterEventHotKey(UInt32(kVK_Space), UInt32(controlKey | optionKey), EventHotKeyID(signature: 0x4155434C, id: 1), GetApplicationEventTarget(), 0, &hotkey)
        if installed != noErr || registered != noErr {
            engine.message = engine.t("全局快捷键被占用，请通过悬浮栏或菜单栏停止。", "The global shortcut is unavailable. Use the floating toolbar or menu bar to stop.")
        }
        engine.onRunningChanged = { [weak self] running in self?.updateEscapeHotkey(running) }
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(systemSymbolName: "cursorarrow.click", accessibilityDescription: engine.appName)
        item.button?.target = self
        item.button?.action = #selector(openStatusMenu)
        statusItem = item
    }

    @objc private func openStatusMenu() {
        guard let engine, let item = statusItem else { return }
        let menu = NSMenu()
        let toggle = NSMenuItem(title: engine.runActionTitle, action: #selector(toggleRun), keyEquivalent: "")
        toggle.target = self
        menu.addItem(toggle)
        if engine.running || engine.paused {
            let stop = NSMenuItem(title: engine.t("停止并重置", "Stop & reset"), action: #selector(stopRun), keyEquivalent: "")
            stop.target = self
            menu.addItem(stop)
        }
        let settings = NSMenuItem(title: engine.t("打开自动点击器", "Open Auto Clicker"), action: #selector(openApp), keyEquivalent: "")
        settings.target = self
        menu.addItem(settings)
        menu.addItem(.separator())
        let quit = NSMenuItem(title: engine.t("退出", "Quit"), action: #selector(quitApp), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
        item.menu = menu
        item.button?.performClick(nil)
        item.menu = nil
    }
    private func updateEscapeHotkey(_ running: Bool) {
        if let escapeHotkey { UnregisterEventHotKey(escapeHotkey); self.escapeHotkey = nil }
        engine?.globalEscapeAvailable = false
        guard running else { return }
        let result = RegisterEventHotKey(UInt32(kVK_Escape), 0, EventHotKeyID(signature: 0x4155434C, id: 2), GetApplicationEventTarget(), 0, &escapeHotkey)
        engine?.globalEscapeAvailable = result == noErr
    }

    @objc private func stopRun() { engine?.stop() }
    @objc private func toggleRun() { engine?.toggleRunning() }
    @objc private func openApp() { engine?.overlays?.showSettings() }
    @objc private func quitApp() { NSApp.terminate(nil) }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag { engine?.overlays?.showSettings() }
        return true
    }
    func applicationWillTerminate(_ notification: Notification) {
        engine?.stop()
        engine?.save()
        if let hotkey { UnregisterEventHotKey(hotkey) }
        if let handler { RemoveEventHandler(handler) }
    }
}
