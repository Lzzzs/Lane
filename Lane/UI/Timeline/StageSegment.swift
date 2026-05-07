import SwiftUI
import LaneCore

struct StageSegment: View {
    let stage: StageInstance
    let geometry: TimelineGeometry

    private static let barHeight: CGFloat = 22

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

    @ViewBuilder
    private func content(width: CGFloat) -> some View {
        let showLabel = width >= 28
        ZStack(alignment: .leading) {
            shape(width: width)
            if showLabel {
                Text(stage.name)
                    .font(LaneFonts.medium(size: 10))
                    .tracking(0.2)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .foregroundStyle(labelColor)
                    .strikethrough(stage.status == .done)
                    .padding(.horizontal, 8)
                    .frame(width: width, alignment: .leading)
            }
            if stage.status == .active {
                progressMarker(width: width)
            }
        }
        .frame(width: width, height: Self.barHeight)
    }

    @ViewBuilder
    private func shape(width: CGFloat) -> some View {
        switch stage.status {
        case .done:
            RoundedRectangle(cornerRadius: 2)
                .fill(LaneColors.tagBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(LaneColors.borderRule, lineWidth: 1)
                )
        case .active:
            RoundedRectangle(cornerRadius: 2)
                .fill(LaneColors.bgCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(LaneColors.ink, lineWidth: 1)
                )
        case .pending:
            RoundedRectangle(cornerRadius: 2)
                .fill(LaneColors.bgCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                        .foregroundStyle(LaneColors.inkFaint)
                )
        case .skipped:
            RoundedRectangle(cornerRadius: 2)
                .fill(LaneColors.bgCard.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(LaneColors.borderHair, lineWidth: 1)
                )
        }
    }

    private func progressMarker(width: CGFloat) -> some View {
        let raw = TimelineGeometry.progress(
            start: stage.startDate!,
            end: stage.endDate!,
            today: Date()
        )
        let p = TimelineGeometry.quantize(raw)
        return Rectangle()
            .fill(LaneColors.ink)
            .frame(width: max(0, p * (width - 2)), height: 2)
            .offset(x: 1, y: Self.barHeight / 2 - 1)
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
