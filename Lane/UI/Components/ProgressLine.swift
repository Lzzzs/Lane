import SwiftUI

struct ProgressLine: View {
    let progress: Double
    var color: Color = LaneColors.ink

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(LaneColors.borderHair)
                    .frame(height: 1)
                Rectangle()
                    .fill(color)
                    .frame(width: max(0, min(1, progress)) * geo.size.width, height: 1)
            }
        }
        .frame(height: 1)
    }
}
