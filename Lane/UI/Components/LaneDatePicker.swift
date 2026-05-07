import SwiftUI

struct LaneDatePicker: View {
    @Binding var date: Date
    var placeholder: String = "—"

    @State private var showingCalendar = false

    var body: some View {
        Button {
            showingCalendar = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(LaneColors.inkMuted)
                Text(formatted(date))
                    .font(LaneFonts.mono(size: 11))
                    .foregroundStyle(LaneColors.ink)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(LaneColors.bgCard)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(LaneColors.borderHair, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .pointingHandCursor()
        .popover(isPresented: $showingCalendar, arrowEdge: .bottom) {
            CalendarPopover(date: $date) {
                showingCalendar = false
            }
        }
    }

    private func formatted(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f.string(from: d)
    }
}

private struct CalendarPopover: View {
    @Binding var date: Date
    let onClose: () -> Void

    private static let presets: [(String, (Date) -> Date)] = [
        ("Today",       { _ in cal.startOfDay(for: Date()) }),
        ("Tomorrow",    { _ in cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: Date()))! }),
        ("+3 days",     { d in cal.date(byAdding: .day, value: 3, to: cal.startOfDay(for: d))! }),
        ("+1 week",     { d in cal.date(byAdding: .day, value: 7, to: cal.startOfDay(for: d))! }),
        ("+2 weeks",    { d in cal.date(byAdding: .day, value: 14, to: cal.startOfDay(for: d))! }),
        ("+1 month",    { d in cal.date(byAdding: .month, value: 1, to: cal.startOfDay(for: d))! }),
        ("Next Monday", { d in nextWeekday(2, from: d) }),
        ("Next Friday", { d in nextWeekday(6, from: d) }),
    ]

    private static let cal = Calendar(identifier: .gregorian)

    private static func nextWeekday(_ target: Int, from date: Date) -> Date {
        let start = cal.startOfDay(for: date)
        let current = cal.component(.weekday, from: start)
        var diff = target - current
        if diff <= 0 { diff += 7 }
        return cal.date(byAdding: .day, value: diff, to: start)!
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            quickPicks
            Divider().background(LaneColors.borderHair)
            DatePicker("", selection: $date, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .labelsHidden()
                .frame(width: 280)
                .padding(.horizontal, 4)
            HStack {
                Spacer()
                Button {
                    onClose()
                } label: {
                    Text("Done")
                        .font(LaneFonts.medium(size: 11))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 5)
                        .background(LaneColors.ink)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .pointingHandCursor()
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .padding(.top, 14)
        .padding(.horizontal, 8)
        .background(LaneColors.bgBase)
        .frame(width: 304)
    }

    private var quickPicks: some View {
        VStack(alignment: .leading, spacing: 6) {
            AllCapsLabel(text: "QUICK", size: 9)
                .padding(.leading, 6)
            FlowLayout(spacing: 6, lineSpacing: 6) {
                ForEach(Array(Self.presets.enumerated()), id: \.offset) { _, preset in
                    let label = preset.0
                    let compute = preset.1
                    Button {
                        date = compute(date)
                    } label: {
                        Text(label)
                            .font(LaneFonts.medium(size: 10))
                            .foregroundStyle(LaneColors.ink)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(LaneColors.tagBg)
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .pointingHandCursor()
                }
            }
            .padding(.horizontal, 6)
        }
    }
}
