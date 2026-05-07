import SwiftUI
import LaneCore

struct TodayLine: View {
    let geometry: TimelineGeometry

    var body: some View {
        let today = Calendar(identifier: .gregorian).startOfDay(for: Date())
        let x = geometry.x(for: today)
        Rectangle()
            .fill(LaneColors.accentNow)
            .frame(width: 1)
            .frame(maxHeight: .infinity)
            .offset(x: x)
            .allowsHitTesting(false)
    }
}
