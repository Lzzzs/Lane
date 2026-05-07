import SwiftUI
import LaneCore

struct StagesRow: View {
    let stages: [StageInstance]
    let geometry: TimelineGeometry

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(stages) { stage in
                StageSegment(stage: stage, geometry: geometry)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: LaneSpacing.trackRowHeight)
        .clipped()
    }
}
