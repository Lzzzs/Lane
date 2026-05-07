import SwiftUI
import LaneCore

struct TimeAxis: View {
    let geometry: TimelineGeometry
    let granularity: TimelineGranularity
    let viewportEnd: Date

    private static let height: CGFloat = 48
    private static let yearStripeHeight: CGFloat = 16

    var body: some View {
        let cal = Calendar(identifier: .gregorian)
        let totalDays = (cal.dateComponents([.day],
            from: geometry.viewportStart, to: viewportEnd).day ?? 0)
        let today = cal.startOfDay(for: today())
        ZStack(alignment: .topLeading) {
            yearStripe(totalDays: totalDays, cal: cal)
            ZStack(alignment: .topLeading) {
                ForEach(0...max(0, totalDays), id: \.self) { offset in
                    let date = cal.date(byAdding: .day, value: offset, to: geometry.viewportStart)!
                    let isToday = cal.isDate(date, inSameDayAs: today)
                    if shouldShowLabel(for: date, today: today, cal: cal) {
                        dayLabel(for: date, today: today, cal: cal)
                            .fixedSize(horizontal: isToday, vertical: false)
                            .frame(width: isToday ? nil : geometry.dayWidth,
                                   height: Self.height - Self.yearStripeHeight,
                                   alignment: .leading)
                            .offset(x: geometry.x(for: date),
                                    y: Self.yearStripeHeight)
                    }
                }
            }
        }
        .frame(height: Self.height)
    }

    @ViewBuilder
    private func yearStripe(totalDays: Int, cal: Calendar) -> some View {
        ZStack(alignment: .topLeading) {
            // Year label at the start of every year that intersects the canvas,
            // plus one for the first visible date so the user always sees an anchor.
            ForEach(yearAnchors(totalDays: totalDays, cal: cal), id: \.date) { anchor in
                Text(anchor.label)
                    .font(LaneFonts.mono(size: 10))
                    .tracking(1.0)
                    .foregroundStyle(LaneColors.inkMuted)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(LaneColors.tagBg)
                    .clipShape(RoundedRectangle(cornerRadius: 3))
                    .offset(x: geometry.x(for: anchor.date) + 4, y: 2)
            }
        }
        .frame(height: Self.yearStripeHeight)
    }

    private struct YearAnchor {
        let date: Date
        let label: String
    }

    private func yearAnchors(totalDays: Int, cal: Calendar) -> [YearAnchor] {
        var anchors: [YearAnchor] = []
        let startYear = cal.component(.year, from: geometry.viewportStart)
        let endYear = cal.component(.year, from: viewportEnd)

        // First visible date acts as the anchor for the starting year.
        anchors.append(YearAnchor(
            date: geometry.viewportStart,
            label: String(startYear)
        ))

        // Jan 1 of each year strictly after start, up to and including endYear.
        var year = startYear + 1
        while year <= endYear {
            var c = DateComponents()
            c.year = year; c.month = 1; c.day = 1
            if let janFirst = cal.date(from: c),
               janFirst >= geometry.viewportStart, janFirst <= viewportEnd {
                anchors.append(YearAnchor(date: janFirst, label: String(year)))
            }
            year += 1
        }
        return anchors
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

    private func today() -> Date { Date() }

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
