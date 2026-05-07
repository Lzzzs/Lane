import SwiftUI
import AppKit

enum LaneFonts {
    private static let bodyName    = "GeneralSans-Regular"
    private static let mediumName  = "GeneralSans-Medium"
    private static let displayName = "GeneralSans-Semibold"
    private static let monoName    = "JetBrainsMono-Regular"
    private static let cjkName     = "PingFangSC-Regular"
    private static let cjkMedium   = "PingFangSC-Medium"

    static func body(size: CGFloat) -> Font {
        Font(cascadeFont(name: bodyName, cjkFallback: cjkName, size: size) as CTFont)
    }

    static func medium(size: CGFloat) -> Font {
        Font(cascadeFont(name: mediumName, cjkFallback: cjkMedium, size: size) as CTFont)
    }

    static func display(size: CGFloat) -> Font {
        Font(cascadeFont(name: displayName, cjkFallback: cjkMedium, size: size) as CTFont)
    }

    static func mono(size: CGFloat) -> Font {
        let f = NSFont(name: monoName, size: size)
            ?? NSFont.monospacedSystemFont(ofSize: size, weight: .regular)
        return Font(f as CTFont)
    }

    private static func cascadeFont(name: String, cjkFallback: String, size: CGFloat) -> NSFont {
        let primary = NSFont(name: name, size: size) ?? NSFont.systemFont(ofSize: size)
        let fallbackDescriptor = NSFontDescriptor(name: cjkFallback, size: size)
        let descriptor = primary.fontDescriptor.addingAttributes([
            NSFontDescriptor.AttributeName(rawValue: "NSCTFontCascadeListAttribute"):
                [fallbackDescriptor]
        ])
        return NSFont(descriptor: descriptor, size: size) ?? primary
    }
}
