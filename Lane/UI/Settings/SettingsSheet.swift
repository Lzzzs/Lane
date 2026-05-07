import SwiftUI
import LaneCore

struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppStore.self) private var app

    @State private var selectedTab: Tab = .general

    enum Tab: String, CaseIterable, Identifiable {
        case general, groups, about
        var id: String { rawValue }
        var label: String {
            switch self {
            case .general: return "GENERAL"
            case .groups:  return "GROUPS"
            case .about:   return "ABOUT"
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider().background(LaneColors.borderHair)
            HStack(alignment: .top, spacing: 0) {
                sidebar
                    .frame(width: 160)
                    .padding(.vertical, 16)
                Divider().background(LaneColors.borderHair)
                ScrollView {
                    Group {
                        switch selectedTab {
                        case .general: generalPane
                        case .groups:  groupsPane
                        case .about:   aboutPane
                        }
                    }
                    .padding(28)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .background(LaneColors.bgBase)
        .frame(width: 720, height: 520)
    }

    private var header: some View {
        HStack {
            AllCapsLabel(text: "SETTINGS", size: 11, color: LaneColors.ink, weight: .semibold)
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(LaneColors.inkMuted)
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .pointingHandCursor()
            .keyboardShortcut(.cancelAction)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(Tab.allCases) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    AllCapsLabel(
                        text: tab.label,
                        size: 10,
                        color: selectedTab == tab ? LaneColors.ink : LaneColors.inkMuted,
                        weight: selectedTab == tab ? .semibold : .medium
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background {
                        if selectedTab == tab {
                            RoundedRectangle(cornerRadius: 4).fill(LaneColors.tagBg)
                        }
                    }
                    .padding(.horizontal, 8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .pointingHandCursor()
            }
        }
    }

    private var generalPane: some View {
        VStack(alignment: .leading, spacing: 24) {
            section("DATABASE") {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Lane stores your data in a single SQLite file.")
                        .font(LaneFonts.body(size: 12))
                        .foregroundStyle(LaneColors.inkMuted)
                    if let url = try? Database.defaultStoreURL() {
                        Text(url.path)
                            .font(LaneFonts.mono(size: 10))
                            .foregroundStyle(LaneColors.inkFaint)
                            .textSelection(.enabled)
                    }
                }
            }

            section("KEYBOARD") {
                shortcutRow("⌘ T", "New requirement")
                shortcutRow("⌘ ,", "Open settings")
            }

            section("STAGE TEMPLATE") {
                Text("Stage templates aren't editable from this build yet — every new requirement uses 评审 → 设计 → 开发 → 联调 → 测试 → 上线 by default. Per-requirement editing is in the requirement detail.")
                    .font(LaneFonts.body(size: 12))
                    .foregroundStyle(LaneColors.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var groupsPane: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Lane groups (swim lanes) are managed inline in the New Requirement sheet. Hover a group there to delete; click \"+ Group\" to create.")
                .font(LaneFonts.body(size: 12))
                .foregroundStyle(LaneColors.inkMuted)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(app.groups) { group in
                    HStack(spacing: 10) {
                        GroupDot(colorHex: group.color, size: 8)
                        Text(group.name)
                            .font(LaneFonts.medium(size: 13))
                            .foregroundStyle(LaneColors.ink)
                        Spacer()
                        Text("\((app.requirementsByGroup[group.id] ?? []).count) requirements")
                            .font(LaneFonts.mono(size: 10))
                            .foregroundStyle(LaneColors.inkFaint)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(LaneColors.bgCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: LaneRadius.card)
                            .stroke(LaneColors.borderHair, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: LaneRadius.card))
                }
            }
        }
    }

    private var aboutPane: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                LaneMark()
                    .frame(width: 36, height: 24)
                VStack(alignment: .leading, spacing: 2) {
                    AllCapsLabel(text: "lane", size: 14, color: LaneColors.ink, weight: .semibold)
                    Text("v0.1.0 · macOS")
                        .font(LaneFonts.mono(size: 10))
                        .foregroundStyle(LaneColors.inkFaint)
                }
            }
            Text("A local-first timeline tracker for parallel work.")
                .font(LaneFonts.body(size: 13))
                .foregroundStyle(LaneColors.inkMuted)
        }
    }

    @ViewBuilder
    private func section<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            AllCapsLabel(text: title, size: 10)
            content()
        }
    }

    private func shortcutRow(_ keys: String, _ label: String) -> some View {
        HStack(spacing: 12) {
            Text(keys)
                .font(LaneFonts.mono(size: 11))
                .foregroundStyle(LaneColors.ink)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(LaneColors.tagBg)
                .clipShape(RoundedRectangle(cornerRadius: 3))
            Text(label)
                .font(LaneFonts.body(size: 12))
                .foregroundStyle(LaneColors.inkMuted)
        }
    }
}
