import SwiftUI
import LaneCore

struct ContentView: View {
    @Environment(AppStore.self) private var app
    @Environment(TimelineStore.self) private var timeline

    @State private var showingNewRequirement = false

    var body: some View {
        VStack(spacing: 0) {
            topBar
            HairLine()
            HStack(spacing: 0) {
                TimelineView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                HairLine(orientation: .vertical)
                TodayPanel()
                    .frame(width: 320)
            }
        }
        .background(LaneColors.bgBase)
        .preferredColorScheme(.light)
        .sheet(isPresented: $showingNewRequirement) {
            NewRequirementSheet()
        }
    }

    private var topBar: some View {
        HStack(spacing: 16) {
            // Leave room for traffic-light buttons under hidden title bar.
            Spacer().frame(width: 60)

            HStack(spacing: 0) {
                LaneMark()
            }
            .frame(width: 44, height: 22)

            AllCapsLabel(text: "lane", size: 11, color: LaneColors.ink, weight: .semibold)

            Spacer()

            ForEach(TimelineGranularity.allCases) { g in
                Button {
                    timeline.setGranularity(g)
                } label: {
                    AllCapsLabel(text: shortLabel(g), size: 10,
                                 color: timeline.granularity == g ? LaneColors.ink : LaneColors.inkMuted)
                }
                .buttonStyle(.plain)
            }

            Button("Today") { timeline.jumpToToday() }
                .buttonStyle(.plain)
                .font(LaneFonts.medium(size: 11))
                .foregroundStyle(LaneColors.ink)

            Divider()
                .frame(height: 16)
                .padding(.horizontal, 4)

            Button {
                showingNewRequirement = true
            } label: {
                HStack(spacing: 6) {
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
            }
            .buttonStyle(.plain)
            .keyboardShortcut("n", modifiers: .command)
        }
        .padding(.horizontal, 20)
        .frame(height: LaneSpacing.topBarHeight)
        .background(LaneColors.bgBase)
    }

    private func shortLabel(_ g: TimelineGranularity) -> String {
        switch g {
        case .day:   return "Day"
        case .week:  return "Week"
        case .month: return "Month"
        }
    }
}

struct LaneMark: View {
    var body: some View {
        Canvas { ctx, size in
            let inkColor = GraphicsContext.Shading.color(LaneColors.ink)
            let lineY1 = size.height * 0.32
            let lineY2 = size.height * 0.72
            let leftPad: CGFloat = 2
            let rightPad: CGFloat = 2
            let lineRect1 = CGRect(x: leftPad, y: lineY1 - 0.75,
                                   width: size.width - leftPad - rightPad, height: 1.5)
            let lineRect2 = CGRect(x: leftPad, y: lineY2 - 0.75,
                                   width: size.width - leftPad - rightPad, height: 1.5)
            ctx.fill(Path(lineRect1), with: inkColor)
            ctx.fill(Path(lineRect2), with: inkColor)

            let seg1 = CGRect(x: size.width * 0.27, y: lineY1 - 3,
                              width: size.width * 0.18, height: 6)
            ctx.fill(Path(seg1), with: inkColor)
            let seg2 = CGRect(x: size.width * 0.50, y: lineY2 - 3,
                              width: size.width * 0.18, height: 6)
            ctx.fill(Path(seg2), with: inkColor)
        }
    }
}
