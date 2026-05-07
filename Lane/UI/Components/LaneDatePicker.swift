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
            VStack(alignment: .leading, spacing: 12) {
                DatePicker("", selection: $date, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .frame(width: 280)
                HStack {
                    Button {
                        date = Calendar(identifier: .gregorian).startOfDay(for: Date())
                    } label: {
                        Text("Today")
                            .font(LaneFonts.medium(size: 11))
                            .foregroundStyle(LaneColors.ink)
                    }
                    .buttonStyle(.plain)
                    .pointingHandCursor()
                    Spacer()
                    Button {
                        showingCalendar = false
                    } label: {
                        Text("Done")
                            .font(LaneFonts.medium(size: 11))
                            .foregroundStyle(LaneColors.ink)
                    }
                    .buttonStyle(.plain)
                    .pointingHandCursor()
                    .keyboardShortcut(.defaultAction)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
            .padding(.top, 12)
            .background(LaneColors.bgBase)
        }
    }

    private func formatted(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f.string(from: d)
    }
}
