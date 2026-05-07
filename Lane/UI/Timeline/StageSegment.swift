import SwiftUI
import LaneCore

struct StageSegment: View {
    let stage: StageInstance
    let geometry: TimelineGeometry

    var body: some View {
        if let start = stage.startDate, let end = stage.endDate {
            let x = geometry.x(for: start)
            let w = geometry.width(from: start, to: end)
            content(width: w)
                .offset(x: x)
        } else {
            unscheduledPlaceholder
        }
    }

    @ViewBuilder
    private func content(width: CGFloat) -> some View {
        ZStack(alignment: .leading) {
            switch stage.status {
            case .done:
                doneStyle(width: width)
            case .active:
                activeStyle(width: width)
            case .pending:
                pendingStyle(width: width)
            case .skipped:
                skippedStyle(width: width)
            }
            if width >= 24 {
                Text(stage.name)
                    .font(LaneFonts.body(size: 10))
                    .foregroundStyle(stage.status == .done ? LaneColors.inkFaint : LaneColors.ink)
                    .strikethrough(stage.status == .done)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .padding(.horizontal, 4)
                    .frame(width: width, alignment: .leading)
            }
        }
        .frame(width: width, height: LaneSpacing.trackRowHeight - 8)
    }

    private func doneStyle(width: CGFloat) -> some View {
        Rectangle()
            .fill(LaneColors.ink)
            .frame(height: 1)
    }

    private func activeStyle(width: CGFloat) -> some View {
        let progress = TimelineGeometry.quantize(
            TimelineGeometry.progress(start: stage.startDate!, end: stage.endDate!, today: Date()))
        return ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 1)
                .stroke(LaneColors.ink, lineWidth: 1)
            RoundedRectangle(cornerRadius: 1)
                .fill(LaneColors.ink)
                .frame(width: max(0, progress * width))
        }
    }

    private func pendingStyle(width: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 1)
            .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
            .foregroundStyle(LaneColors.inkMuted)
    }

    private func skippedStyle(width: CGFloat) -> some View {
        Rectangle()
            .fill(LaneColors.inkFaint.opacity(0.3))
    }

    private var unscheduledPlaceholder: some View {
        EmptyView()
    }
}
