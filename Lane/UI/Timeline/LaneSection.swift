import SwiftUI
import LaneCore

struct LaneSection: View {
    let group: LaneCore.Group
    let requirements: [Requirement]
    let stagesByRequirement: [String: [StageInstance]]
    let geometry: TimelineGeometry
    let canvasWidth: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.leading, LaneSpacing.cardPaddingS + 12)
                .padding(.vertical, 12)
            ZStack(alignment: .topLeading) {
                Rectangle()
                    .fill(Color(hexString: group.color))
                    .frame(width: LaneSpacing.laneRulerWidth)
                    .padding(.leading, LaneSpacing.cardPaddingS - 1)
                VStack(spacing: 0) {
                    ForEach(requirements) { req in
                        RequirementRow(
                            requirement: req,
                            stages: stagesByRequirement[req.id] ?? [],
                            geometry: geometry,
                            canvasWidth: canvasWidth
                        )
                    }
                }
            }
            HairLine()
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            AllCapsLabel(text: group.name, size: 11)
            Text("\(requirements.count)")
                .font(LaneFonts.mono(size: 10))
                .foregroundStyle(LaneColors.inkFaint)
            Spacer()
        }
    }
}
