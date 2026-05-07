import SwiftUI
import LaneCore

struct TimelineView: View {
    @Environment(AppStore.self) private var app
    @Environment(TimelineStore.self) private var timeline

    let onSelect: (String) -> Void

    static let titleColumnWidth: CGFloat = 200
    static let timeAxisHeight: CGFloat = 56
    static let laneHeaderHeight: CGFloat = 40

    @State private var zoomBaseline: CGFloat? = nil
    @State private var zoomAnchorOffsetInCanvas: CGFloat? = nil
    @State private var zoomAnchorScreenX: CGFloat? = nil
    @State private var hScrollOffsetX: CGFloat = 0
    @State private var pendingScrollToToday: Bool = true

    var body: some View {
        let g = TimelineGeometry(
            viewportStart: timeline.viewportStart,
            dayWidth: timeline.effectiveDayWidth)
        let canvasWidth = visibleCanvasWidth()

        ScrollView(.vertical, showsIndicators: false) {
            HStack(alignment: .top, spacing: 0) {
                titleColumn
                    .frame(width: Self.titleColumnWidth, alignment: .leading)

                GeometryReader { proxy in
                    TimelineHorizontalScroll(
                        offsetX: $hScrollOffsetX,
                        contentWidth: canvasWidth,
                        scrollFactor: 0.5
                    ) {
                        ZStack(alignment: .topLeading) {
                            timelineCanvas(geometry: g, width: canvasWidth)
                            TodayLine(geometry: g)
                        }
                        .frame(width: canvasWidth, alignment: .topLeading)
                    }
                    .onAppear {
                        if pendingScrollToToday {
                            pendingScrollToToday = false
                            let viewW = proxy.size.width
                            hScrollOffsetX = max(0, g.x(for: today()) - viewW / 2)
                        }
                    }
                    .onChange(of: timeline.jumpToTodayCounter) { _, _ in
                        let viewW = proxy.size.width
                        withAnimation(.easeInOut(duration: 0.25)) {
                            hScrollOffsetX = max(0, g.x(for: today()) - viewW / 2)
                        }
                    }
                    .onChange(of: timeline.effectiveDayWidth) { oldWidth, newWidth in
                        // When the day-width changes outside of an active pinch
                        // (i.e. the user clicked a granularity preset), keep the
                        // visible centre on the same date by rescaling the scroll
                        // offset proportionally.
                        guard zoomBaseline == nil, oldWidth > 0 else { return }
                        let viewW = proxy.size.width
                        let centerInCanvas = hScrollOffsetX + viewW / 2
                        let scale = newWidth / oldWidth
                        let newCenter = centerInCanvas * scale
                        hScrollOffsetX = max(0, newCenter - viewW / 2)
                    }
                    .gesture(zoomGesture(viewWidth: proxy.size.width))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(LaneColors.bgBase)
    }

    private func zoomGesture(viewWidth: CGFloat) -> some Gesture {
        MagnifyGesture(minimumScaleDelta: 0.02)
            .onChanged { value in
                if zoomBaseline == nil {
                    zoomBaseline = timeline.effectiveDayWidth
                    let cursorScreenX = value.startLocation.x
                    zoomAnchorScreenX = cursorScreenX
                    zoomAnchorOffsetInCanvas = hScrollOffsetX + cursorScreenX
                }
                guard let base = zoomBaseline,
                      let anchorOffset = zoomAnchorOffsetInCanvas,
                      let anchorScreen = zoomAnchorScreenX else { return }
                let oldWidth = timeline.effectiveDayWidth
                let raw = value.magnification
                let damped = raw >= 1
                    ? 1 + (raw - 1) * 0.4
                    : 1 - (1 - raw) * 0.4
                timeline.setDayWidth(base * damped)
                let scale = timeline.effectiveDayWidth / oldWidth
                let newAnchor = anchorOffset * scale
                hScrollOffsetX = max(0, newAnchor - anchorScreen)
                zoomAnchorOffsetInCanvas = newAnchor
                _ = viewWidth
            }
            .onEnded { _ in
                zoomBaseline = nil
                zoomAnchorOffsetInCanvas = nil
                zoomAnchorScreenX = nil
            }
    }

    private func today() -> Date {
        Calendar(identifier: .gregorian).startOfDay(for: Date())
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
            Color.clear.frame(height: 16)
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
            Color.clear.frame(height: 16)
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
        return CGFloat(days) * timeline.effectiveDayWidth
    }
}
