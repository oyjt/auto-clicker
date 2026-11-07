import AppKit
import SwiftUI

// WeChat green for surfaces, a deeper adaptive shade for readable glyphs.
enum ClickerTheme {
    static let nsGreen = NSColor(srgbRed: 7 / 255, green: 193 / 255, blue: 96 / 255, alpha: 1)
    static let nsAccent = NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            ? nsGreen : NSColor(srgbRed: 3 / 255, green: 125 / 255, blue: 62 / 255, alpha: 1)
    }
    static let green = Color(nsColor: nsGreen)
    static let accent = Color(nsColor: nsAccent)
    static let onGreen = Color(red: 0, green: 0.20, blue: 0.09)
}
