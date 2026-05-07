import SwiftUI
import LaneCore

struct NewRequirementSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppStore.self) private var app

    @State private var title: String = ""
    @State private var selectedGroupId: String = ""
    @State private var startsToday: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            AllCapsLabel(text: "NEW REQUIREMENT", size: 11, color: LaneColors.ink, weight: .semibold)

            VStack(alignment: .leading, spacing: 8) {
                AllCapsLabel(text: "TITLE", size: 10)
                TextField("e.g. 登录改造", text: $title)
                    .textFieldStyle(.plain)
                    .font(LaneFonts.body(size: 15))
                    .padding(10)
                    .background(LaneColors.bgCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: LaneRadius.card)
                            .stroke(LaneColors.borderHair, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: LaneRadius.card))
            }

            VStack(alignment: .leading, spacing: 8) {
                AllCapsLabel(text: "GROUP", size: 10)
                HStack(spacing: 8) {
                    ForEach(app.groups) { group in
                        groupPill(group)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                AllCapsLabel(text: "STARTING STAGE", size: 10)
                Toggle(isOn: $startsToday) {
                    Text("Schedule first stage starting today (3 days)")
                        .font(LaneFonts.body(size: 12))
                        .foregroundStyle(LaneColors.inkMuted)
                }
                .toggleStyle(.checkbox)
            }

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Create") { create() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || selectedGroupId.isEmpty)
            }
        }
        .padding(28)
        .frame(width: 460)
        .background(LaneColors.bgBase)
        .onAppear {
            if selectedGroupId.isEmpty {
                selectedGroupId = app.groups.first?.id ?? ""
            }
        }
    }

    @ViewBuilder
    private func groupPill(_ group: LaneCore.Group) -> some View {
        let selected = group.id == selectedGroupId
        Button {
            selectedGroupId = group.id
        } label: {
            HStack(spacing: 6) {
                GroupDot(colorHex: group.color, size: 6)
                Text(group.name)
                    .font(LaneFonts.medium(size: 11))
                    .foregroundStyle(selected ? LaneColors.ink : LaneColors.inkMuted)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(selected ? LaneColors.tagBg : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(selected ? LaneColors.borderRule : LaneColors.borderHair, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.plain)
    }

    private func create() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !selectedGroupId.isEmpty else { return }
        let groupId = selectedGroupId
        let toggle = startsToday
        Task {
            do {
                _ = try await app.createRequirement(
                    title: trimmed,
                    groupId: groupId,
                    scheduleFirstStageToday: toggle
                )
                dismiss()
            } catch {
                NSLog("Lane new requirement failed: \(error)")
            }
        }
    }
}
