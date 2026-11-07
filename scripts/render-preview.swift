import AppKit
import SwiftUI
import ClickerCore

// Offscreen rendering of the real SwiftUI views, without sending mouse events.
@main
struct Preview {
    @MainActor static func main() throws {
        let app = NSApplication.shared
        app.setActivationPolicy(.prohibited)
        app.applicationIconImage = NSImage(contentsOfFile: "Resources/AppIcon.png")
        let defaults = UserDefaults.standard
        let originalAppearance = defaults.object(forKey: "appearance")
        let originalLanguage = defaults.object(forKey: "language")
        defer {
            if let originalAppearance { defaults.set(originalAppearance, forKey: "appearance") } else { defaults.removeObject(forKey: "appearance") }
            if let originalLanguage { defaults.set(originalLanguage, forKey: "language") } else { defaults.removeObject(forKey: "language") }
        }
        let engine = ClickEngine()
        let folder = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        for (name, page, appearance, language) in [
            ("workspace-light-zh", "workspace", AppearanceMode.light, AppLanguage.zh),
            ("workspace-dark-en", "workspace", .dark, .en),
            ("workspace-paused-zh", "workspace", .light, .zh),
            ("settings-dark-en", "settings", .dark, .en),
            ("timing-light-en", "timing", .light, .en),
            ("settings-light-zh", "settings", .light, .zh),
            ("timing-light-zh", "timing", .light, .zh)
        ] {
            engine.page = page; engine.appearance = appearance; engine.language = language
            engine.paused = name.contains("paused")
            engine.enabled = engine.paused
            engine.completedClicks = engine.paused ? 12 : 0
            engine.completedCycles = engine.paused ? 12 : 0
            let view = NSHostingView(rootView: MainView(engine: engine))
            view.frame = CGRect(x: 0, y: 0, width: 1000, height: page == "workspace" ? 710 : 880)
            let window = NSWindow(contentRect: view.frame, styleMask: [.titled], backing: .buffered, defer: false)
            window.contentView = view
            window.appearance = NSApp.appearance
            view.layoutSubtreeIfNeeded()
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
            guard let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { fatalError("Could not render view") }
            view.cacheDisplay(in: view.bounds, to: rep)
            try rep.representation(using: .png, properties: [:])!.write(to: folder.appendingPathComponent(name + ".png"))
            window.orderOut(nil)
        }
        engine.language = .zh
        for (name, running, paused, appearance) in [
            ("toolbar-ready", false, false, AppearanceMode.light),
            ("toolbar-running", true, false, .light),
            ("toolbar-paused", false, true, .light),
            ("toolbar-dark", true, false, .dark)
        ] {
            engine.appearance = appearance
            engine.running = running
            engine.paused = paused
            let controller = OverlayController(engine: engine)
            let toolbar = NSHostingView(rootView: FloatingControls(engine: engine, controller: controller))
            toolbar.frame = CGRect(origin: .zero, size: ToolbarLayout.size)
            let panel = FloatingPanel(size: toolbar.frame.size)
            panel.contentView = toolbar
            panel.appearance = NSApp.appearance
            toolbar.layoutSubtreeIfNeeded()
            RunLoop.current.run(until: Date().addingTimeInterval(0.15))
            let image = toolbar.bitmapImageRepForCachingDisplay(in: toolbar.bounds)!
            toolbar.cacheDisplay(in: toolbar.bounds, to: image)
            try image.representation(using: .png, properties: [:])!.write(to: folder.appendingPathComponent(name + ".png"))
            if name == "toolbar-ready" || name == "toolbar-running" {
                let target = TargetView(engine: engine, controller: controller, id: engine.plan.points[0].id, number: 1)
                let targetImage = target.bitmapImageRepForCachingDisplay(in: target.bounds)!
                target.cacheDisplay(in: target.bounds, to: targetImage)
                try targetImage.representation(using: .png, properties: [:])!.write(to: folder.appendingPathComponent(running ? "target-running.png" : "target-ready.png"))
            }
        }
        engine.paused = false
        engine.appearance = .light
        engine.running = false
        let point = engine.plan.points[0]
        let editor = NSHostingView(rootView: PointEditor(engine: engine, point: point, close: {}))
        editor.frame = CGRect(x: 0, y: 0, width: 440, height: 440)
        let window = NSWindow(contentRect: editor.frame, styleMask: [.titled], backing: .buffered, defer: false)
        window.contentView = editor
        editor.layoutSubtreeIfNeeded()
        RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        let rep = editor.bitmapImageRepForCachingDisplay(in: editor.bounds)!
        editor.cacheDisplay(in: editor.bounds, to: rep)
        try rep.representation(using: .png, properties: [:])!.write(to: folder.appendingPathComponent("point-editor.png"))
    }
}
