import SwiftUI
import LaneCore

struct TodayPanel: View {
    @Environment(AppStore.self) private var app

    let onSelect: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
                .background(LaneColors.borderHair)
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    inProgressSection
                    if !pinnedRequirements.isEmpty {
                        pinnedSection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
        }
        .background(LaneColors.bgBase)
        .frame(maxHeight: .infinity)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            AllCapsLabel(text: "TODAY", size: 11, color: LaneColors.ink, weight: .semibold)
            Text(longDateString())
                .font(LaneFonts.mono(size: 11))
                .foregroundStyle(LaneColors.inkMuted)
                .textCase(.uppercase)
                .tracking(0.6)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }

    private var inProgressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                AllCapsLabel(text: "IN PROGRESS", size: 11)
                Text("\(inProgressRequirements.count)")
                    .font(LaneFonts.mono(size: 10))
                    .foregroundStyle(LaneColors.inkFaint)
                Spacer()
            }
            if inProgressRequirements.isEmpty {
                Text("Nothing actively scheduled today.")
                    .font(LaneFonts.body(size: 12))
                    .foregroundStyle(LaneColors.inkFaint)
                    .padding(.vertical, 12)
            } else {
                ForEach(inProgressRequirements) { req in
                    Button {
                        onSelect(req.id)
                    } label: {
                        TodayCard(requirement: req,
                                  groupName: groupName(for: req),
                                  groupColor: groupColor(for: req),
                                  currentStage: currentStage(for: req))
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var pinnedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                AllCapsLabel(text: "PINNED FOR TODAY", size: 11)
                Text("\(pinnedRequirements.count)")
                    .font(LaneFonts.mono(size: 10))
                    .foregroundStyle(LaneColors.inkFaint)
                Spacer()
            }
            ForEach(pinnedRequirements) { req in
                TodayCard(requirement: req,
                          groupName: groupName(for: req),
                          groupColor: groupColor(for: req),
                          currentStage: currentStage(for: req))
            }
        }
    }

    private var inProgressRequirements: [Requirement] {
        let cal = Calendar(identifier: .gregorian)
        let today = cal.startOfDay(for: Date())
        let allActive = app.requirementsByGroup.values.flatMap { $0 }
        return allActive.filter { req in
            let stages = app.stagesByRequirement[req.id] ?? []
            return stages.contains { stage in
                guard let s = stage.startDate, let e = stage.endDate else { return false }
                let sd = cal.startOfDay(for: s)
                let ed = cal.startOfDay(for: e)
                return today >= sd && today <= ed &&
                    (stage.status == .active || stage.status == .pending)
            }
        }
        .sorted { $0.sortOrder < $1.sortOrder }
    }

    private var pinnedRequirements: [Requirement] {
        []  // Pinning UI lands in a follow-up; keep section empty for now.
    }

    private func currentStage(for req: Requirement) -> StageInstance? {
        let cal = Calendar(identifier: .gregorian)
        let today = cal.startOfDay(for: Date())
        let stages = app.stagesByRequirement[req.id] ?? []
        return stages.first { stage in
            guard let s = stage.startDate, let e = stage.endDate else { return false }
            let sd = cal.startOfDay(for: s)
            let ed = cal.startOfDay(for: e)
            return today >= sd && today <= ed
        } ?? stages.first { $0.status == .active }
    }

    private func groupName(for req: Requirement) -> String {
        app.groups.first { $0.id == req.groupId }?.name ?? ""
    }

    private func groupColor(for req: Requirement) -> String {
        app.groups.first { $0.id == req.groupId }?.color ?? "#000000"
    }

    private func longDateString() -> String {
        let f = DateFormatter()
        f.dateFormat = "MMMM d, yyyy · EEE"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f.string(from: Date())
    }
}

private struct TodayCard: View {
    let requirement: Requirement
    let groupName: String
    let groupColor: String
    let currentStage: StageInstance?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                GroupDot(colorHex: groupColor, size: 6)
                AllCapsLabel(text: groupName, size: 9, color: LaneColors.inkMuted)
                Spacer()
            }
            Text(requirement.title)
                .font(LaneFonts.medium(size: 14))
                .foregroundStyle(LaneColors.ink)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            if let stage = currentStage {
                HStack(spacing: 8) {
                    Text(stage.name)
                        .font(LaneFonts.body(size: 11))
                        .foregroundStyle(LaneColors.inkMuted)
                    Text("·")
                        .font(LaneFonts.body(size: 11))
                        .foregroundStyle(LaneColors.inkFaint)
                    Text(stage.status.rawValue.uppercased())
                        .font(LaneFonts.mono(size: 9))
                        .tracking(0.6)
                        .foregroundStyle(LaneColors.inkFaint)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LaneColors.bgCard)
        .overlay(
            RoundedRectangle(cornerRadius: LaneRadius.card)
                .stroke(LaneColors.borderHair, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: LaneRadius.card))
    }
}
