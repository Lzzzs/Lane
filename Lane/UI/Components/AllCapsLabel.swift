import SwiftUI

struct AllCapsLabel: View {
    let text: String
    var size: CGFloat = 11
    var color: Color = LaneColors.inkMuted
    var weight: Font.Weight = .medium

    var body: some View {
        Text(text.uppercased())
            .font(LaneFonts.medium(size: size).weight(weight))
            .tracking(1.6)
            .foregroundStyle(color)
    }
}
