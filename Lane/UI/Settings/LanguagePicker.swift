import SwiftUI

enum LanePreferredLanguage: String, CaseIterable, Identifiable {
    case system, english, chinese

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system:  return "System"
        case .english: return "English"
        case .chinese: return "简体中文"
        }
    }

    /// Locale identifier to apply via .environment(\.locale, ...).
    var localeIdentifier: String? {
        switch self {
        case .system:  return nil
        case .english: return "en_US"
        case .chinese: return "zh_Hans"
        }
    }
}

struct LanguagePicker: View {
    @AppStorage("lane.preferredLanguage") private var raw: String = LanePreferredLanguage.system.rawValue

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                ForEach(LanePreferredLanguage.allCases) { lang in
                    Button {
                        raw = lang.rawValue
                    } label: {
                        Text(lang.label)
                            .font(LaneFonts.medium(size: 12))
                            .foregroundStyle(selected(lang) ? LaneColors.ink : LaneColors.inkMuted)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selected(lang) ? LaneColors.tagBg : Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(selected(lang) ? LaneColors.borderRule : LaneColors.borderHair,
                                            lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .pointingHandCursor()
                }
            }
            Text("Restart the app for the language change to take effect across the UI.")
                .font(LaneFonts.body(size: 11))
                .foregroundStyle(LaneColors.inkFaint)
        }
    }

    private func selected(_ lang: LanePreferredLanguage) -> Bool {
        raw == lang.rawValue
    }
}
