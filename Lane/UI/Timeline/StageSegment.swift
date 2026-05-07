import SwiftUI
import LaneCore

struct StageSegment: View {
    let stage: StageInstance
    let geometry: TimelineGeometry

    private static let labelFont: CGFloat = 10
    private static let trackHeight: CGFloat = 26

    var body: some View {
        if let start = stage.startDate, let end = stage.endDate {
            let x = geometry.x(for: start)
            let w = geometry.width(from: start, to: end)
            content(width: w)
                .offset(x: x)
        } else {
            EmptyView()
        }
    }

    private func content(width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            label(width: width)
                .frame(width: width, alignment: .leading)
            line(width: width)
                .frame(width: width)
        }
        .frame(width: width, height: Self.trackHeight, alignment: .topLeading)
    }

    @ViewBuilder
    private func label(width: CGFloat) -> some View {
        if width >= 22 {
            Text(stage.name)
                .font(LaneFonts.medium(size: Self.labelFont))
                .lineLimit(1)
                .truncationMode(.tail)
                .foregroundStyle(labelColor)
                .strikethrough(stage.status == .done)
                .padding(.leading, 2)
        }
    }

    @ViewBuilder
    private func line(width: CGFloat) -> some View {
        switch stage.status {
        case .done:
            Capsule()
                .fill(LaneColors.inkFaint)
                .frame(height: 2)
        case .active:
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(LaneColors.borderRule)
                    .frame(height: 2)
                Capsule()
                    .fill(LaneColors.ink)
                    .frame(width: progressWidth(width: width), height: 2)
            }
        case .pending:
            Rectangle()
                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                .foregroundStyle(LaneColors.inkFaint)
                .frame(height: 2)
        case .skipped:
            Capsule()
                .fill(LaneColors.borderHair)
                .frame(height: 2)
        }
    }

    private func progressWidth(width: CGFloat) -> CGFloat {
        let raw = TimelineGeometry.progress(
            start: stage.startDate!, end: stage.endDate!, today: Date())
        let p = TimelineGeometry.quantize(raw)
        return max(0, p * width)
    }

    private var labelColor: Color {
        switch stage.status {
        case .done:    return LaneColors.inkFaint
        case .active:  return LaneColors.ink
        case .pending: return LaneColors.inkMuted
        case .skipped: return LaneColors.inkFaint
        }
    }
}
