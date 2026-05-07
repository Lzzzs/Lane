import SwiftUI
import LaneCore

struct TimeAxis: View {
    let geometry: TimelineGeometry
    let granularity: TimelineGranularity
    let viewportEnd: Date

    var body: some View {
        let cal = Calendar(identifier: .gregorian)
        let totalDays = (cal.dateComponents([.day],
            from: geometry.viewportStart, to: viewportEnd).day ?? 0)
        let today = cal.startOfDay(for: Date())
        ZStack(alignment: .topLeading) {
            ForEach(0...max(0, totalDays), id: \.self) { offset in
                let date = cal.date(byAdding: .day, value: offset, to: geometry.viewportStart)!
                let isToday = cal.isDate(date, inSameDayAs: today)
                if shouldShowLabel(for: date, today: today, cal: cal) {
                    dayLabel(for: date, today: today, cal: cal)
                        .fixedSize(horizontal: isToday, vertical: false)
                        .frame(width: isToday ? nil : geometry.dayWidth,
                               height: 32, alignment: .leading)
                        .offset(x: geometry.x(for: date))
                }
            }
        }
        .frame(height: 32)
    }

    private func shouldShowLabel(for date: Date, today: Date, cal: Calendar) -> Bool {
        if cal.isDate(date, inSameDayAs: today) { return true }
        switch granularity {
        case .day, .week:
            return true
        case .month:
            return cal.component(.weekday, from: date) == 2
        }
    }

    @ViewBuilder
    private func dayLabel(for date: Date, today: Date, cal: Calendar) -> some View {
        let isToday = cal.isDate(date, inSameDayAs: today)
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(monthDay(date))
                    .font(LaneFonts.mono(size: 10))
                    .foregroundStyle(isToday ? LaneColors.ink : LaneColors.inkMuted)
                    .fontWeight(isToday ? .semibold : .regular)
                if isToday {
                    Text("TODAY")
                        .font(LaneFonts.mono(size: 8))
                        .tracking(0.6)
                        .foregroundStyle(LaneColors.ink)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(LaneColors.ink.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 2))
                }
            }
            if granularity != .month {
                Text(weekday(date))
                    .font(LaneFonts.mono(size: 9))
                    .foregroundStyle(isToday ? LaneColors.inkMuted : LaneColors.inkFaint)
            }
        }
        .padding(.leading, 4)
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
