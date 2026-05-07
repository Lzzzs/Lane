import SwiftUI
import LaneCore

struct TimelineView: View {
    @Environment(AppStore.self) private var app
    @Environment(TimelineStore.self) private var timeline

    var body: some View {
        GeometryReader { geo in
            let g = TimelineGeometry(
                viewportStart: timeline.viewportStart,
                dayWidth: timeline.granularity.dayWidth)

            ScrollView([.horizontal, .vertical]) {
                ZStack(alignment: .topLeading) {
                    canvas(geometry: g, canvasWidth: canvasWidth(geo: geo))
                    TodayLine(geometry: g, height: contentHeight)
                        .frame(maxHeight: .infinity, alignment: .top)
                }
                .frame(width: canvasWidth(geo: geo), alignment: .topLeading)
            }
        }
    }

    private func canvas(geometry g: TimelineGeometry, canvasWidth: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            TimeAxis(geometry: g,
                     granularity: timeline.granularity,
                     viewportEnd: timeline.viewportEnd)
                .frame(width: canvasWidth, alignment: .leading)
            HairLine()
            ForEach(visibleGroups) { group in
                LaneSection(
                    group: group,
                    requirements: app.requirementsByGroup[group.id] ?? [],
                    stagesByRequirement: app.stagesByRequirement,
                    geometry: g,
                    canvasWidth: canvasWidth
                )
            }
            Spacer(minLength: 100)
        }
    }

    private var visibleGroups: [LaneCore.Group] {
        if timeline.visibleGroupIds.isEmpty { return app.groups }
        return app.groups.filter { timeline.visibleGroupIds.contains($0.id) }
    }

    private var contentHeight: CGFloat {
        let rows = app.requirementsByGroup.values.reduce(0) { $0 + $1.count }
        let headers = visibleGroups.count
        return CGFloat(rows) * LaneSpacing.trackRowHeight + CGFloat(headers) * 44 + 28
    }

    private func canvasWidth(geo: GeometryProxy) -> CGFloat {
        let cal = Calendar(identifier: .gregorian)
        let days = cal.dateComponents([.day],
            from: timeline.viewportStart, to: timeline.viewportEnd).day ?? 0
        return CGFloat(days + 1) * timeline.granularity.dayWidth + 200
    }
}
