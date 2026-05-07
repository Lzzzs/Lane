import SwiftUI
import LaneCore

struct RequirementRow: View {
    let requirement: Requirement
    let stages: [StageInstance]
    let geometry: TimelineGeometry
    let canvasWidth: CGFloat

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            titleColumn
                .frame(width: 160, alignment: .leading)
                .padding(.leading, LaneSpacing.cardPaddingS)
            timelineColumn
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: LaneSpacing.trackRowHeight)
    }

    private var titleColumn: some View {
        Text(requirement.title)
            .font(LaneFonts.body(size: 13))
            .foregroundStyle(LaneColors.ink)
            .lineLimit(1)
            .truncationMode(.tail)
    }

    private var timelineColumn: some View {
        ZStack(alignment: .topLeading) {
            ForEach(stages) { stage in
                StageSegment(stage: stage, geometry: geometry)
            }
        }
    }
}
