import SwiftUI
import LaneCore

struct TimelineView: View {
    @Environment(AppStore.self) private var app
    @Environment(TimelineStore.self) private var timeline

    let onSelect: (String) -> Void

    static let titleColumnWidth: CGFloat = 200
    static let timeAxisHeight: CGFloat = 32
    static let laneHeaderHeight: CGFloat = 40

    var body: some View {
        GeometryReader { proxy in
            let availableTimelineWidth = max(0, proxy.size.width - Self.titleColumnWidth)
            let g = TimelineGeometry(
                viewportStart: timeline.viewportStart,
                dayWidth: timeline.granularity.dayWidth)
            let canvasWidth = visibleCanvasWidth()

            ScrollView(.vertical, showsIndicators: false) {
                HStack(alignment: .top, spacing: 0) {
                    titleColumn
                        .frame(width: Self.titleColumnWidth, alignment: .leading)
                    ZStack(alignment: .topLeading) {
                        timelineCanvas(geometry: g, width: max(canvasWidth, availableTimelineWidth))
                        TodayLine(geometry: g)
                    }
                    .frame(width: max(canvasWidth, availableTimelineWidth), alignment: .topLeading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(LaneColors.bgBase)
            .onAppear { timeline.fitTo(availableWidth: availableTimelineWidth) }
            .onChange(of: availableTimelineWidth) { _, newWidth in
                timeline.fitTo(availableWidth: newWidth)
            }
            .onChange(of: timeline.granularity) { _, _ in
                timeline.fitTo(availableWidth: availableTimelineWidth)
            }
        }
    }

    private var titleColumn: some View {
        VStack(alignment: .leading, spacing: 0) {
            Color.clear.frame(height: Self.timeAxisHeight)
            HairLine()
            ForEach(visibleGroups) { group in
                laneTitleSection(group: group)
            }
        }
    }

    private func laneTitleSection(group: LaneCore.Group) -> some View {
        let reqs = app.requirementsByGroup[group.id] ?? []
        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                AllCapsLabel(text: group.name, size: 11)
                Text("\(reqs.count)")
                    .font(LaneFonts.mono(size: 10))
                    .foregroundStyle(LaneColors.inkFaint)
                Spacer(minLength: 0)
            }
            .padding(.leading, LaneSpacing.cardPaddingS + 12)
            .frame(height: Self.laneHeaderHeight, alignment: .leading)

            ZStack(alignment: .topLeading) {
                Rectangle()
                    .fill(Color(hexString: group.color))
                    .frame(width: LaneSpacing.laneRulerWidth)
                    .padding(.leading, LaneSpacing.cardPaddingS)

                VStack(spacing: 0) {
                    ForEach(reqs) { req in
                        Button {
                            onSelect(req.id)
                        } label: {
                            Text(req.title)
                                .font(LaneFonts.body(size: 13))
                                .foregroundStyle(LaneColors.ink)
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.leading, LaneSpacing.cardPaddingS + 12)
                                .padding(.trailing, 8)
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(height: LaneSpacing.trackRowHeight)
                        .contentShape(Rectangle())
                        .pointingHandCursor()
                    }
                }
            }
            HairLine()
        }
    }

    private func timelineCanvas(geometry g: TimelineGeometry, width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            TimeAxis(geometry: g,
                     granularity: timeline.granularity,
                     viewportEnd: timeline.viewportEnd)
                .frame(width: width, height: Self.timeAxisHeight, alignment: .leading)
            HairLine()
            ForEach(visibleGroups) { group in
                laneStagesSection(group: group, geometry: g, width: width)
            }
        }
    }

    private func laneStagesSection(group: LaneCore.Group,
                                   geometry: TimelineGeometry,
                                   width: CGFloat) -> some View {
        let reqs = app.requirementsByGroup[group.id] ?? []
        return VStack(spacing: 0) {
            Color.clear.frame(height: Self.laneHeaderHeight)
            VStack(spacing: 0) {
                ForEach(reqs) { req in
                    Button {
                        onSelect(req.id)
                    } label: {
                        StagesRow(
                            stages: app.stagesByRequirement[req.id] ?? [],
                            geometry: geometry
                        )
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: LaneSpacing.trackRowHeight)
                    .contentShape(Rectangle())
                    .pointingHandCursor()
                }
            }
            HairLine()
        }
        .frame(width: width, alignment: .leading)
    }

    private var visibleGroups: [LaneCore.Group] {
        if timeline.visibleGroupIds.isEmpty { return app.groups }
        return app.groups.filter { timeline.visibleGroupIds.contains($0.id) }
    }

    private func visibleCanvasWidth() -> CGFloat {
        let cal = Calendar(identifier: .gregorian)
        let days = (cal.dateComponents([.day],
            from: timeline.viewportStart, to: timeline.viewportEnd).day ?? 0) + 1
        return CGFloat(days) * timeline.granularity.dayWidth
    }
}
