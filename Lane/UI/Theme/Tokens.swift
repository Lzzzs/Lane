import SwiftUI

enum LaneColors {
    static let bgBase     = Color(hex: 0xFAFAF7)
    static let bgCard     = Color.white
    static let borderHair = Color(hex: 0xE8E6E1)
    static let borderRule = Color(hex: 0xDEDAD2)

    static let ink        = Color(hex: 0x1A1A18)
    static let inkMuted   = Color(hex: 0x8A8682)
    static let inkFaint   = Color(hex: 0xB5B0AA)

    static let tagBg      = Color(hex: 0xF0EEE8)
    static let tagInk     = Color(hex: 0x5C5852)

    static let accentNow  = Color(hex: 0x000000)
    static let accentWarn = Color(hex: 0xB8542E)

    static let groupPalette: [String] = [
        "#7A8C7A",
        "#8A7A6A",
        "#9B7B6B",
        "#7B8A95",
        "#A8896B",
        "#7A8A85",
        "#8B7B8E",
        "#6E7B6E",
    ]
}

enum LaneSpacing {
    static let cardPaddingS: CGFloat = 16
    static let cardPaddingM: CGFloat = 20
    static let cardPaddingL: CGFloat = 24
    static let cardGap: CGFloat = 12
    static let sectionGap: CGFloat = 32
    static let topBarHeight: CGFloat = 56
    static let trackRowHeight: CGFloat = 36
    static let laneRulerWidth: CGFloat = 3
}

enum LaneRadius {
    static let card: CGFloat = 4
    static let pill: CGFloat = 999
}

extension Color {
    init(hex: UInt32, opacity: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8)  & 0xFF) / 255
        let b = Double(hex         & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }

    init(hexString: String) {
        let s = hexString.hasPrefix("#") ? String(hexString.dropFirst()) : hexString
        let v = UInt32(s, radix: 16) ?? 0
        self.init(hex: v)
    }
}
