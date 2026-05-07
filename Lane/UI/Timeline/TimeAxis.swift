import SwiftUI
import LaneCore

struct TimeAxis: View {
    let geometry: TimelineGeometry
    let granularity: TimelineGranularity
    let viewportEnd: Date

    private static let height: CGFloat = 56
    private static let yearStripeHeight: CGFloat = 18
    private static let labelBottomPadding: CGFloat = 6

    enum DensityMode {
        case everyDay
        case everyOther
        case weekly        // Mondays
        case biweekly      // Every other Monday
        case monthly       // 1st of month
        case quarterly     // Jan / Apr / Jul / Oct 1st
    }

    var body: some View {
        let cal = Calendar(identifier: .gregorian)
        let totalDays = (cal.dateComponents([.day],
            from: geometry.viewportStart, to: viewportEnd).day ?? 0)
        let today = cal.startOfDay(for: today())
        let mode = densityMode(for: geometry.dayWidth)
        ZStack(alignment: .topLeading) {
            yearStripe(totalDays: totalDays, cal: cal)
            tickStripe(totalDays: totalDays, mode: mode, today: today, cal: cal)
            labelStripe(totalDays: totalDays, mode: mode, today: today, cal: cal)
        }
        .frame(height: Self.height)
    }

    // MARK: - Density

    private func densityMode(for dayWidth: CGFloat) -> DensityMode {
        switch dayWidth {
        case 50...:    return .everyDay
        case 28..<50:  return .everyOther
        case 14..<28:  return .weekly
        case 8..<14:   return .biweekly
        case 4..<8:    return .monthly
        default:       return .quarterly
        }
    }

    private func showsWeekday(_ mode: DensityMode) -> Bool {
        switch mode {
        case .everyDay, .everyOther: return granularity != .month
        default: return false
        }
    }

    private func showsLabel(for date: Date, today: Date,
                            mode: DensityMode, cal: Calendar) -> Bool {
        if cal.isDate(date, inSameDayAs: today) { return true }
        switch mode {
        case .everyDay:
            return true
        case .everyOther:
            // Anchor the rhythm to a fixed reference (Sunday = day-of-year even/odd
            // would jitter on year boundaries; instead, stride from canvas start).
            let offset = cal.dateComponents([.day],
                from: geometry.viewportStart, to: date).day ?? 0
            return offset.isMultiple(of: 2)
        case .weekly:
            return cal.component(.weekday, from: date) == 2  // Monday
        case .biweekly:
            guard cal.component(.weekday, from: date) == 2 else { return false }
            let week = cal.component(.weekOfYear, from: date)
            return week.isMultiple(of: 2)
        case .monthly:
            return cal.component(.day, from: date) == 1
        case .quarterly:
            let day = cal.component(.day, from: date)
            let month = cal.component(.month, from: date)
            return day == 1 && [1, 4, 7, 10].contains(month)
        }
    }

    private func showsTick(for date: Date, today: Date,
                           mode: DensityMode, cal: Calendar) -> Bool {
        if mode == .everyDay { return false }    // Labels are dense enough.
        if cal.isDate(date, inSameDayAs: today) { return false }
        return !showsLabel(for: date, today: today, mode: mode, cal: cal)
    }

    // MARK: - Strips

    @ViewBuilder
    private func tickStripe(totalDays: Int, mode: DensityMode,
                            today: Date, cal: Calendar) -> some View {
        let tickColor = LaneColors.borderHair
        let tickHeight: CGFloat = mode == .quarterly ? 6 : 4
        let baselineY = Self.height - Self.labelBottomPadding - tickHeight
        ZStack(alignment: .topLeading) {
            ForEach(0...max(0, totalDays), id: \.self) { offset in
                let date = cal.date(byAdding: .day, value: offset, to: geometry.viewportStart)!
                if showsTick(for: date, today: today, mode: mode, cal: cal) {
                    Rectangle()
                        .fill(tickColor)
                        .frame(width: 1, height: tickHeight)
                        .offset(x: geometry.x(for: date), y: baselineY)
                }
            }
        }
    }

    @ViewBuilder
    private func labelStripe(totalDays: Int, mode: DensityMode,
                             today: Date, cal: Calendar) -> some View {
        ZStack(alignment: .topLeading) {
            ForEach(0...max(0, totalDays), id: \.self) { offset in
                let date = cal.date(byAdding: .day, value: offset, to: geometry.viewportStart)!
                let isToday = cal.isDate(date, inSameDayAs: today)
                if showsLabel(for: date, today: today, mode: mode, cal: cal) {
                    dayLabel(for: date, today: today, mode: mode, cal: cal)
                        .fixedSize(horizontal: true, vertical: false)
                        .frame(height: Self.height - Self.yearStripeHeight - Self.labelBottomPadding,
                               alignment: .topLeading)
                        .offset(x: labelX(for: date, isToday: isToday),
                                y: Self.yearStripeHeight)
                }
            }
        }
    }

    /// Place wide labels (today, monthly, quarterly) so they don't lean off
    /// the right edge of their day's tick.
    private func labelX(for date: Date, isToday: Bool) -> CGFloat {
        // For "every day" / "every other" densities, fixedSize labels can
        // overflow the day cell; align so today's label centers on its tick.
        geometry.x(for: date)
    }

    @ViewBuilder
    private func yearStripe(totalDays: Int, cal: Calendar) -> some View {
        ZStack(alignment: .topLeading) {
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

        anchors.append(YearAnchor(
            date: geometry.viewportStart,
            label: String(startYear)
        ))

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

    @ViewBuilder
    private func dayLabel(for date: Date, today: Date, mode: DensityMode,
                          cal: Calendar) -> some View {
        let isToday = cal.isDate(date, inSameDayAs: today)
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(label(for: date, mode: mode))
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
            if showsWeekday(mode) {
                Text(weekday(date))
                    .font(LaneFonts.mono(size: 9))
                    .foregroundStyle(isToday ? LaneColors.inkMuted : LaneColors.inkFaint)
            }
        }
        .padding(.leading, 4)
    }

    private func label(for date: Date, mode: DensityMode) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        switch mode {
        case .everyDay, .everyOther, .weekly, .biweekly:
            f.dateFormat = "M/d"
        case .monthly:
            f.dateFormat = "MMM"
        case .quarterly:
            f.dateFormat = "MMM"
        }
        return f.string(from: date)
    }

    private func today() -> Date { Date() }

    private func weekday(_ d: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "EEE"
        return f.string(from: d).uppercased()
    }
}
