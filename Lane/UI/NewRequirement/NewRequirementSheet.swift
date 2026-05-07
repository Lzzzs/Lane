import SwiftUI
import LaneCore

struct NewRequirementSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppStore.self) private var app

    @State private var title: String = ""
    @State private var selectedGroupId: String = ""
    @State private var startsToday: Bool = true
    @State private var showingNewGroup = false
    @State private var groupPendingDelete: String? = nil

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
                        GroupPill(
                            group: group,
                            selected: group.id == selectedGroupId,
                            action: { selectedGroupId = group.id }
                        )
                        .pointingHandCursor()
                        .contextMenu {
                            Button(role: .destructive) {
                                groupPendingDelete = group.id
                            } label: {
                                Text("Delete \"\(group.name)\"")
                            }
                        }
                    }
                    addGroupChip
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
        .popover(isPresented: $showingNewGroup, arrowEdge: .bottom) {
            NewGroupPopover { newId in
                selectedGroupId = newId
            }
            .environment(app)
        }
        .alert(
            "Delete this group?",
            isPresented: Binding(
                get: { groupPendingDelete != nil },
                set: { if !$0 { groupPendingDelete = nil } }
            )
        ) {
            Button("Cancel", role: .cancel) { groupPendingDelete = nil }
            Button("Delete", role: .destructive) { confirmDeleteGroup() }
        } message: {
            Text("Groups can only be deleted when they have no active requirements.")
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

    private func confirmDeleteGroup() {
        guard let id = groupPendingDelete else { return }
        groupPendingDelete = nil
        if selectedGroupId == id {
            selectedGroupId = app.groups.first { $0.id != id }?.id ?? ""
        }
        Task { try? await app.deleteGroup(id: id) }
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
