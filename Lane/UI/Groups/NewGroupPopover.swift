import SwiftUI
import LaneCore

struct NewGroupPopover: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppStore.self) private var app

    var onCreated: ((String) -> Void)? = nil

    @State private var name: String = ""
    @State private var colorHex: String = LaneColors.groupPalette.first ?? "#7A8C7A"
    @State private var icon: String = "●"

    private static let icons: [String] = ["●", "◆", "▲", "■", "★", "▶"]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            AllCapsLabel(text: "NEW GROUP", size: 11, color: LaneColors.ink, weight: .semibold)

            VStack(alignment: .leading, spacing: 6) {
                AllCapsLabel(text: "NAME", size: 9)
                TextField("e.g. 学习", text: $name)
                    .textFieldStyle(.plain)
                    .font(LaneFonts.body(size: 13))
                    .padding(8)
                    .background(LaneColors.bgCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(LaneColors.borderHair, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .onSubmit { create() }
            }

            VStack(alignment: .leading, spacing: 6) {
                AllCapsLabel(text: "ICON", size: 9)
                HStack(spacing: 6) {
                    ForEach(Self.icons, id: \.self) { sym in
                        iconChip(sym)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                AllCapsLabel(text: "COLOR", size: 9)
                HStack(spacing: 6) {
                    ForEach(LaneColors.groupPalette, id: \.self) { hex in
                        colorChip(hex)
                    }
                }
            }

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Create") { create() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.top, 4)
        }
        .padding(20)
        .frame(width: 320)
    }

    private func iconChip(_ sym: String) -> some View {
        let selected = icon == sym
        return Button {
            icon = sym
        } label: {
            Text(sym)
                .font(LaneFonts.medium(size: 14))
                .foregroundStyle(selected ? LaneColors.ink : LaneColors.inkMuted)
                .frame(width: 28, height: 28)
                .background(selected ? LaneColors.tagBg : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(selected ? LaneColors.borderRule : LaneColors.borderHair, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func colorChip(_ hex: String) -> some View {
        let selected = colorHex == hex
        return Button {
            colorHex = hex
        } label: {
            Circle()
                .fill(Color(hexString: hex))
                .frame(width: 22, height: 22)
                .overlay(
                    Circle().stroke(selected ? LaneColors.ink : Color.clear, lineWidth: 2)
                )
                .padding(2)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }

    private func create() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let n = trimmed
        let c = colorHex
        let i = icon
        let cb = onCreated
        Task {
            if let group = try? await app.createGroup(name: n, color: c, icon: i) {
                cb?(group.id)
            }
            dismiss()
        }
    }
}
