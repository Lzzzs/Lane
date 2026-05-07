import SwiftUI
import LaneCore

struct ContentView: View {
    @Environment(AppStore.self) private var app
    @Environment(TimelineStore.self) private var timeline

    @State private var showingNewRequirement = false
    @State private var showingNewGroup = false
    @State private var editingRequirementId: String? = nil

    var body: some View {
        HStack(spacing: 0) {
            TimelineView(onSelect: { editingRequirementId = $0 })
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            HairLine(orientation: .vertical)
            TodayPanel(onSelect: { editingRequirementId = $0 })
                .frame(width: 320)
        }
        .background(LaneColors.bgBase)
        .preferredColorScheme(.light)
        .navigationTitle("Lane")
        .toolbar { toolbarContent }
        .onChange(of: app.groups.map(\.id)) { _, newIds in
            for id in newIds where !timeline.visibleGroupIds.contains(id) {
                timeline.visibleGroupIds.insert(id)
            }
        }
        .sheet(isPresented: $showingNewRequirement) {
            NewRequirementSheet().environment(app)
        }
        .sheet(item: editingRequirementBinding) { wrapper in
            EditRequirementSheet(requirementId: wrapper.id).environment(app)
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigation) {
            HStack(spacing: 8) {
                LaneMark()
                    .frame(width: 24, height: 14)
                AllCapsLabel(text: "lane", size: 11, color: LaneColors.ink, weight: .semibold)
            }
        }

        ToolbarItemGroup(placement: .principal) {
            ForEach(TimelineGranularity.allCases) { g in
                Button {
                    timeline.setGranularity(g)
                } label: {
                    AllCapsLabel(
                        text: shortLabel(g),
                        size: 10,
                        color: timeline.granularity == g ? LaneColors.ink : LaneColors.inkMuted
                    )
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }

        ToolbarItemGroup(placement: .primaryAction) {
            Button {
                showingNewGroup = true
            } label: {
                Image(systemName: "rectangle.stack.badge.plus")
                    .font(.system(size: 12, weight: .medium))
            }
            .buttonStyle(.plain)
            .help("New group")
            .popover(isPresented: $showingNewGroup, arrowEdge: .top) {
                NewGroupPopover().environment(app)
            }

            Button {
                showingNewRequirement = true
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .medium))
                    Text("New")
                        .font(LaneFonts.medium(size: 11))
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .keyboardShortcut("n", modifiers: .command)
        }
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
