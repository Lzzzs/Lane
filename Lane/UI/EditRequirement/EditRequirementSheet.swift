import SwiftUI
import LaneCore

struct EditRequirementSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppStore.self) private var app

    let requirementId: String

    @State private var title: String = ""
    @State private var description: String = ""
    @State private var groupId: String = ""
    @State private var stages: [StageInstance] = []
    @State private var loaded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider().background(LaneColors.borderHair)
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    titleField
                    groupField
                    stagesField
                    descriptionField
                }
                .padding(28)
            }
            footer
        }
        .background(LaneColors.bgBase)
        .frame(width: 560, height: 640)
        .onAppear { hydrate() }
    }

    private var header: some View {
        HStack(spacing: 8) {
            AllCapsLabel(text: "EDIT REQUIREMENT", size: 11, color: LaneColors.ink, weight: .semibold)
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
            .keyboardShortcut(.cancelAction)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 18)
    }

    private var titleField: some View {
        VStack(alignment: .leading, spacing: 8) {
            AllCapsLabel(text: "TITLE", size: 10)
            TextField("", text: $title)
                .textFieldStyle(.plain)
                .font(LaneFonts.medium(size: 18))
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(LaneColors.bgCard)
                .overlay(
                    RoundedRectangle(cornerRadius: LaneRadius.card)
                        .stroke(LaneColors.borderHair, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: LaneRadius.card))
                .onSubmit { save() }
        }
    }

    private var groupField: some View {
        VStack(alignment: .leading, spacing: 8) {
            AllCapsLabel(text: "GROUP", size: 10)
            HStack(spacing: 8) {
                ForEach(app.groups) { group in
                    GroupPill(
                        group: group,
                        selected: group.id == groupId,
                        action: { groupId = group.id }
                    )
                }
            }
        }
    }

    private var stagesField: some View {
        VStack(alignment: .leading, spacing: 12) {
            AllCapsLabel(text: "STAGES", size: 10)
            ForEach($stages) { $stage in
                StageEditorRow(stage: $stage)
            }
        }
    }

    private var descriptionField: some View {
        VStack(alignment: .leading, spacing: 8) {
            AllCapsLabel(text: "NOTES", size: 10)
            TextEditor(text: $description)
                .font(LaneFonts.body(size: 13))
                .scrollContentBackground(.hidden)
                .padding(8)
                .frame(minHeight: 80)
                .background(LaneColors.bgCard)
                .overlay(
                    RoundedRectangle(cornerRadius: LaneRadius.card)
                        .stroke(LaneColors.borderHair, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: LaneRadius.card))
        }
    }

    private var footer: some View {
        HStack {
            Button(role: .destructive) {
                Task {
                    try? await app.deleteRequirement(id: requirementId)
                    dismiss()
                }
            } label: {
                Text("Delete")
                    .font(LaneFonts.medium(size: 12))
                    .foregroundStyle(LaneColors.accentWarn)
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("Cancel")
                    .font(LaneFonts.medium(size: 12))
                    .foregroundStyle(LaneColors.inkMuted)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                save()
            } label: {
                Text("Save")
                    .font(LaneFonts.medium(size: 12))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(LaneColors.ink)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.defaultAction)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 16)
        .background(LaneColors.bgBase)
        .overlay(alignment: .top) { HairLine() }
    }

    private func hydrate() {
        guard !loaded else { return }
        loaded = true
        let req = app.requirementsByGroup.values.flatMap { $0 }
            .first { $0.id == requirementId }
        title = req?.title ?? ""
        description = req?.description ?? ""
        groupId = req?.groupId ?? app.groups.first?.id ?? ""
        stages = (app.stagesByRequirement[requirementId] ?? [])
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let req = app.requirementsByGroup.values.flatMap { $0 }
            .first { $0.id == requirementId }
        guard var req else { return }
        req.title = trimmed
        req.description = description
        req.groupId = groupId
        let stagesCopy = stages
        Task {
            try? await app.updateRequirement(req)
            for stage in stagesCopy {
                try? await app.updateStage(stage)
            }
            dismiss()
        }
    }
}

private struct StageEditorRow: View {
    @Binding var stage: StageInstance

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            statusIcon
                .frame(width: 18)

            Text(stage.name)
                .font(LaneFonts.medium(size: 13))
                .foregroundStyle(LaneColors.ink)
                .frame(width: 80, alignment: .leading)

            DatePicker("", selection: startBinding, displayedComponents: .date)
                .labelsHidden()
                .datePickerStyle(.compact)

            Text("→")
                .foregroundStyle(LaneColors.inkFaint)

            DatePicker("", selection: endBinding, displayedComponents: .date)
                .labelsHidden()
                .datePickerStyle(.compact)

            Spacer(minLength: 0)

            Menu {
                ForEach([StageStatus.pending, .active, .done, .skipped], id: \.rawValue) { s in
                    Button(s.rawValue.capitalized) { stage.status = s }
                }
                Divider()
                Button("Clear dates") {
                    stage.startDate = nil
                    stage.endDate = nil
                    stage.status = .pending
                }
            } label: {
                AllCapsLabel(text: stage.status.rawValue, size: 9)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(LaneColors.tagBg)
                    .clipShape(RoundedRectangle(cornerRadius: 3))
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch stage.status {
        case .done:
            Image(systemName: "checkmark")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(LaneColors.ink)
        case .active:
            Image(systemName: "play.fill")
                .font(.system(size: 9))
                .foregroundStyle(LaneColors.ink)
        case .pending:
            Image(systemName: "circle")
                .font(.system(size: 11))
                .foregroundStyle(LaneColors.inkMuted)
        case .skipped:
            Image(systemName: "minus")
                .font(.system(size: 11))
                .foregroundStyle(LaneColors.inkFaint)
        }
    }

    private var startBinding: Binding<Date> {
        Binding(
            get: { stage.startDate ?? Date() },
            set: { newValue in
                stage.startDate = newValue
                if stage.endDate == nil || (stage.endDate ?? newValue) < newValue {
                    stage.endDate = Calendar(identifier: .gregorian)
                        .date(byAdding: .day, value: 3, to: newValue)
                }
            }
        )
    }

    private var endBinding: Binding<Date> {
        Binding(
            get: { stage.endDate ?? stage.startDate ?? Date() },
            set: { stage.endDate = $0 }
        )
    }
}

struct GroupPill: View {
    let group: LaneCore.Group
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
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
            .contentShape(RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.plain)
    }
}
