import SwiftUI
import LaneCore

struct NewRequirementSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppStore.self) private var app

    @State private var title: String = ""
    @State private var selectedGroupId: String = ""
    @State private var startsToday: Bool = true
    @State private var showingNewGroup = false
    @State private var deleteError: String? = nil

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
                FlowLayout(spacing: 8, lineSpacing: 8) {
                    ForEach(app.groups) { group in
                        DeletableGroupPill(
                            group: group,
                            selected: group.id == selectedGroupId,
                            onSelect: { selectedGroupId = group.id },
                            onDelete: { tryDelete(group) }
                        )
                    }
                    addGroupChip
                        .popover(isPresented: $showingNewGroup, arrowEdge: .trailing) {
                            NewGroupPopover { newId in
                                selectedGroupId = newId
                            }
                            .environment(app)
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
        .frame(width: 520)
        .background(LaneColors.bgBase)
        .onAppear {
            if selectedGroupId.isEmpty {
                selectedGroupId = app.groups.first?.id ?? ""
            }
        }
        .alert(
            "Can't delete group",
            isPresented: Binding(
                get: { deleteError != nil },
                set: { if !$0 { deleteError = nil } }
            )
        ) {
            Button("OK") { deleteError = nil }
        } message: {
            Text(deleteError ?? "")
        }
    }

    private var addGroupChip: some View {
        Button {
            showingNewGroup = true
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "plus")
                    .font(.system(size: 10, weight: .medium))
                Text("Group")
                    .font(LaneFonts.medium(size: 11))
            }
            .foregroundStyle(LaneColors.inkMuted)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    .foregroundStyle(LaneColors.borderHair)
            )
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .contentShape(RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.plain)
        .pointingHandCursor()
    }

    private func tryDelete(_ group: LaneCore.Group) {
        let count = (app.requirementsByGroup[group.id] ?? []).count
        if count > 0 {
            deleteError = "\"\(group.name)\" still has \(count) requirement(s). Move or archive them before deleting the group."
            return
        }
        let id = group.id
        if selectedGroupId == id {
            selectedGroupId = app.groups.first { $0.id != id }?.id ?? ""
        }
        Task {
            do {
                try await app.deleteGroup(id: id)
            } catch {
                deleteError = "Couldn't delete \"\(group.name)\": \(error.localizedDescription)"
            }
        }
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

private struct DeletableGroupPill: View {
    let group: LaneCore.Group
    let selected: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void

    @State private var hovering = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: onSelect) {
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
            .pointingHandCursor()

            if hovering {
                Button(action: onDelete) {
                    Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(LaneColors.bgBase)
                        .frame(width: 14, height: 14)
                        .background(Circle().fill(LaneColors.ink))
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .pointingHandCursor()
                .help("Delete group")
                .offset(x: 4, y: -4)
            }
        }
        .onHover { hovering = $0 }
        .padding(2)
    }
}

/// Minimal flow layout that wraps content to a new row when needed.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, lineH: CGFloat = 0
        var maxRowWidth: CGFloat = 0
        for sub in subviews {
            let s = sub.sizeThatFits(.unspecified)
            if x + s.width > maxWidth, x > 0 {
                y += lineH + lineSpacing
                x = 0; lineH = 0
            }
            x += s.width + spacing
            lineH = max(lineH, s.height)
            maxRowWidth = max(maxRowWidth, x - spacing)
        }
        return CGSize(width: maxRowWidth, height: y + lineH)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, lineH: CGFloat = 0
        for sub in subviews {
            let s = sub.sizeThatFits(.unspecified)
            if x + s.width > bounds.maxX, x > bounds.minX {
                y += lineH + lineSpacing
                x = bounds.minX; lineH = 0
            }
            sub.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(s))
            x += s.width + spacing
            lineH = max(lineH, s.height)
        }
    }
}
