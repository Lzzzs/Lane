import SwiftUI

struct HairLine: View {
    var color: Color = LaneColors.borderHair
    var orientation: Axis = .horizontal

    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: orientation == .horizontal ? nil : 1,
                   height: orientation == .horizontal ? 1 : nil)
    }
}
