import AppKit
import SwiftUI
import ClickerCore

enum AppearanceMode: String, CaseIterable { case system, light, dark }
enum AppLanguage: String, CaseIterable { case system, zh, en }

extension ClickEngine {
    var isEnglish: Bool {
        language == .en || (language == .system && !(Locale.preferredLanguages.first ?? "en").hasPrefix("zh"))
    }
    func t(_ chinese: String, _ english: String) -> String { isEnglish ? english : chinese }
    var appName: String { t("自动点击器", "Auto Clicker") }
    func kindName(_ kind: ClickKind) -> String {
        switch kind {
        case .left: return t("左键单击", "Left click")
        case .right: return t("右键单击", "Right click")
        case .double: return t("左键双击", "Double click")
        }
    }
    func applyAppearance() {
        NSApp.appearance = appearance == .system ? nil : NSAppearance(named: appearance == .dark ? .darkAqua : .aqua)
        overlays?.refresh()
    }
}
