import SwiftUI
import LaneCore

struct TodayLine: View {
    let geometry: TimelineGeometry
    let height: CGFloat

    var body: some View {
        let today = Calendar(identifier: .gregorian).startOfDay(for: Date())
        let x = geometry.x(for: today)
        ZStack(alignment: .top) {
            Rectangle()
                .fill(LaneColors.accentNow)
                .frame(width: 1, height: height)
            VStack(spacing: 4) {
                Circle()
                    .fill(LaneColors.accentNow)
                    .frame(width: 6, height: 6)
                AllCapsLabel(text: "TODAY", size: 9, color: LaneColors.ink)
            }
            .offset(x: -22, y: -4)
        }
        .offset(x: x)
    }
}
