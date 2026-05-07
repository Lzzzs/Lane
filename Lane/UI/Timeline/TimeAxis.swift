import SwiftUI
import LaneCore

struct TimeAxis: View {
    let geometry: TimelineGeometry
    let granularity: TimelineGranularity
    let viewportEnd: Date

    var body: some View {
        let cal = Calendar(identifier: .gregorian)
        let days = stride(from: 0,
                          through: cal.dateComponents([.day],
                              from: geometry.viewportStart, to: viewportEnd).day ?? 0,
                          by: 1)
        ZStack(alignment: .topLeading) {
            ForEach(Array(days), id: \.self) { offset in
                let date = cal.date(byAdding: .day, value: offset, to: geometry.viewportStart)!
                dayLabel(for: date)
                    .frame(width: geometry.dayWidth, height: 28, alignment: .leading)
                    .offset(x: geometry.x(for: date))
            }
        }
        .frame(height: 28)
    }

    @ViewBuilder
    private func dayLabel(for date: Date) -> some View {
        let cal = Calendar(identifier: .gregorian)
        let isToday = cal.isDateInToday(date)
        switch granularity {
        case .day, .week:
            VStack(alignment: .leading, spacing: 2) {
                Text(monthDay(date))
                    .font(LaneFonts.mono(size: 10))
                    .foregroundStyle(isToday ? LaneColors.ink : LaneColors.inkMuted)
                Text(weekday(date))
                    .font(LaneFonts.mono(size: 9))
                    .foregroundStyle(LaneColors.inkFaint)
            }
            .padding(.leading, 4)
        case .month:
            if cal.component(.weekday, from: date) == 2 {
                Text(monthDay(date))
                    .font(LaneFonts.mono(size: 9))
                    .foregroundStyle(LaneColors.inkMuted)
                    .padding(.leading, 2)
            } else {
                EmptyView()
            }
        }
    }

    private func monthDay(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "M/d"
        return f.string(from: d)
    }

    private func weekday(_ d: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "EEE"
        return f.string(from: d).uppercased()
    }
}
