import SwiftUI
import LaneCore

struct ContentView: View {
    @Environment(AppStore.self) private var app
    @Environment(TimelineStore.self) private var timeline

    @State private var showingNewRequirement = false
    @State private var showingSettings = false
    @State private var editingRequirementId: String? = nil

    @Namespace private var granularitySelection

    var body: some View {
        VStack(spacing: 0) {
            topBar
            HairLine()
            HStack(spacing: 0) {
                TimelineView(onSelect: { editingRequirementId = $0 })
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                HairLine(orientation: .vertical)
                TodayPanel(onSelect: { editingRequirementId = $0 })
                    .frame(width: 320)
            }
        }
        .background(LaneColors.bgBase)
        .preferredColorScheme(.light)
        .ignoresSafeArea(.container, edges: .top)
        .onChange(of: app.groups.map(\.id)) { _, newIds in
            for id in newIds where !timeline.visibleGroupIds.contains(id) {
                timeline.visibleGroupIds.insert(id)
            }
        }
        .sheet(isPresented: $showingNewRequirement) {
            NewRequirementSheet().environment(app)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsSheet().environment(app)
        }
        .sheet(item: editingRequirementBinding) { wrapper in
            EditRequirementSheet(requirementId: wrapper.id).environment(app)
        }
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            // Traffic-light area (hidden title bar)
            Spacer().frame(width: 70)

            HStack(spacing: 8) {
                LaneMark()
                    .frame(width: 24, height: 14)
                AllCapsLabel(text: "lane", size: 11, color: LaneColors.ink, weight: .semibold)
            }

            Spacer()

            granularityPill

            Spacer()

            HStack(spacing: 8) {
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(LaneColors.inkMuted)
                        .padding(6)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .pointingHandCursor()
                .help("Settings")
                .keyboardShortcut(",", modifiers: .command)

                Button {
                    showingNewRequirement = true
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .medium))
                        Text("New")
                            .font(LaneFonts.medium(size: 11))
                    }
                    .foregroundStyle(LaneColors.ink)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(LaneColors.borderRule, lineWidth: 1)
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .pointingHandCursor()
                .keyboardShortcut("t", modifiers: .command)
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 36)
    }

    private var granularityPill: some View {
        HStack(spacing: 0) {
            ForEach(TimelineGranularity.allCases) { g in
                let isActive = timeline.isUsingPreset && timeline.granularity == g
                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
                        timeline.setGranularity(g)
                    }
                } label: {
                    AllCapsLabel(
                        text: shortLabel(g),
                        size: 10,
                        color: isActive ? LaneColors.ink : LaneColors.inkMuted,
                        weight: isActive ? .semibold : .medium
                    )
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                    .background {
                        if isActive {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(LaneColors.bgCard)
                                .matchedGeometryEffect(id: "granularitySelection", in: granularitySelection)
                                .shadow(color: LaneColors.ink.opacity(0.04), radius: 1, y: 0.5)
                        }
                    }
                }
                .buttonStyle(.plain)
                .pointingHandCursor()
            }
        }
        .padding(2)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(LaneColors.tagBg.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(LaneColors.borderHair, lineWidth: 0.5)
                )
        )
    }

    private var editingRequirementBinding: Binding<IdentifiableString?> {
        Binding(
            get: { editingRequirementId.map(IdentifiableString.init) },
            set: { editingRequirementId = $0?.id }
        )
    }

    private func shortLabel(_ g: TimelineGranularity) -> String {
        switch g {
        case .day:   return "Day"
        case .week:  return "Week"
        case .month: return "Month"
        }
    }
}

private struct IdentifiableString: Identifiable {
    let id: String
}

struct LaneMark: View {
    var body: some View {
        Canvas { ctx, size in
            let inkColor = GraphicsContext.Shading.color(LaneColors.ink)
            let lineY1 = size.height * 0.32
            let lineY2 = size.height * 0.72
            let leftPad: CGFloat = 1
            let rightPad: CGFloat = 1
            let lineRect1 = CGRect(x: leftPad, y: lineY1 - 0.5,
                                   width: size.width - leftPad - rightPad, height: 1)
            let lineRect2 = CGRect(x: leftPad, y: lineY2 - 0.5,
                                   width: size.width - leftPad - rightPad, height: 1)
            ctx.fill(Path(lineRect1), with: inkColor)
            ctx.fill(Path(lineRect2), with: inkColor)

            let seg1 = CGRect(x: size.width * 0.27, y: lineY1 - 2,
                              width: size.width * 0.18, height: 4)
            ctx.fill(Path(seg1), with: inkColor)
            let seg2 = CGRect(x: size.width * 0.50, y: lineY2 - 2,
                              width: size.width * 0.18, height: 4)
            ctx.fill(Path(seg2), with: inkColor)
        }
    }
}
