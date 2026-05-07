import SwiftUI

struct MicroTag: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(LaneFonts.medium(size: 9))
            .tracking(0.8)
            .foregroundStyle(LaneColors.tagInk)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(LaneColors.tagBg)
            .clipShape(RoundedRectangle(cornerRadius: 2))
    }
}
