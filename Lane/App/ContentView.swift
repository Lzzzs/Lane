import SwiftUI
import LaneCore

struct ContentView: View {
    @Environment(AppStore.self) private var app
    @Environment(TimelineStore.self) private var timeline

    var body: some View {
        VStack(spacing: 0) {
            topBar
            HairLine()
            TimelineView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(LaneColors.bgBase)
        .overlay(alignment: .top) {
            LinearGradient(colors: [Color(hex: 0xF5E8DD).opacity(0.8), .clear],
                           startPoint: .top, endPoint: .bottom)
                .frame(height: 220)
                .allowsHitTesting(false)
        }
    }

    private var topBar: some View {
        HStack(spacing: 16) {
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
        }
        .padding(.horizontal, 20)
        .frame(height: LaneSpacing.topBarHeight)
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

#Preview {
    ContentView()
}
