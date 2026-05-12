import SwiftUI
import LaneCore

struct TimelineView: View {
    @Environment(AppStore.self) private var app
    @Environment(TimelineStore.self) private var timeline

    let onSelect: (String) -> Void
    @Binding var isAtToday: Bool

    static let titleColumnWidth: CGFloat = 200
    static let timeAxisHeight: CGFloat = 56
    static let laneHeaderHeight: CGFloat = 40

    @State private var zoomBaseline: CGFloat? = nil
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

                ScrollViewReader { hProxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        ZStack(alignment: .topLeading) {
                            timelineCanvas(geometry: g, width: canvasWidth)
                            TodayLine(geometry: g)
                            // Hidden anchor at today's x for ScrollViewReader.
                            HStack(spacing: 0) {
                                Color.clear.frame(width: max(0, g.x(for: today()) - 1))
                                Color.clear.frame(width: 2).id("today")
                                Spacer(minLength: 0)
                            }
                            .frame(width: canvasWidth, height: 1)
                            .allowsHitTesting(false)
                        }
                        .frame(width: canvasWidth, alignment: .topLeading)
                    }
                    .onAppear {
                        if pendingScrollToToday {
                            pendingScrollToToday = false
                            DispatchQueue.main.async {
                                hProxy.scrollTo("today", anchor: .center)
                                isAtToday = true
                            }
                        }
                    }
                    .onChange(of: timeline.jumpToTodayCounter) { _, _ in
                        withAnimation(.easeInOut(duration: 0.25)) {
                            hProxy.scrollTo("today", anchor: .center)
                        }
                        isAtToday = true
                    }
                    .gesture(zoomGesture)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(LaneColors.bgBase)
    }

    private var zoomGesture: some Gesture {
        MagnifyGesture(minimumScaleDelta: 0.02)
            .onChanged { value in
                if zoomBaseline == nil {
                    zoomBaseline = timeline.effectiveDayWidth
                }
                guard let base = zoomBaseline else { return }
                let raw = value.magnification
                let damped = raw >= 1
                    ? 1 + (raw - 1) * 0.12
                    : 1 - (1 - raw) * 0.12
                timeline.setDayWidth(base * damped)
                isAtToday = false
            }
            .onEnded { _ in
                zoomBaseline = nil
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
