import Foundation
import Observation

public enum TimelineGranularity: String, CaseIterable, Identifiable {
    case day, week, month
    public var id: String { rawValue }

    public var dayWidth: CGFloat {
        switch self {
        case .day:   return 200
        case .week:  return 64
        case .month: return 18
        }
    }

    public var defaultVisibleDays: Int {
        switch self {
        case .day:   return 5
        case .week:  return 14
        case .month: return 60
        }
    }
}

@Observable
@MainActor
public final class TimelineStore {
    public private(set) var granularity: TimelineGranularity = .week
    public private(set) var viewportStart: Date
    public private(set) var viewportEnd: Date

    public var visibleGroupIds: Set<String> = []

    private let calendar: Calendar = Calendar(identifier: .gregorian)

    public init() {
        let cal = Calendar(identifier: .gregorian)
        let today = cal.startOfDay(for: Date())
        let half = TimelineGranularity.week.defaultVisibleDays / 2
        viewportStart = cal.date(byAdding: .day, value: -half, to: today)!
        viewportEnd   = cal.date(byAdding: .day, value:  half, to: today)!
    }

    public func setGranularity(_ g: TimelineGranularity) {
        granularity = g
        jumpToToday()
    }

    public func jumpToToday() {
        let today = calendar.startOfDay(for: Date())
        let half = granularity.defaultVisibleDays / 2
        viewportStart = calendar.date(byAdding: .day, value: -half, to: today)!
        viewportEnd   = calendar.date(byAdding: .day, value:  half, to: today)!
    }

    public func scroll(byDays days: Int) {
        viewportStart = calendar.date(byAdding: .day, value: days, to: viewportStart)!
        viewportEnd   = calendar.date(byAdding: .day, value: days, to: viewportEnd)!
    }

    /// Resize the viewport so it spans `availableWidth / dayWidth` days,
    /// keeping today centered when today is currently in view.
    public func fitTo(availableWidth: CGFloat) {
        let dayWidth = granularity.dayWidth
        guard dayWidth > 0, availableWidth > 0 else { return }
        let totalDays = max(granularity.defaultVisibleDays,
                            Int(availableWidth / dayWidth))
        let half = totalDays / 2
        let today = calendar.startOfDay(for: Date())
        let pinnedToday = today >= viewportStart && today <= viewportEnd
        let anchor = pinnedToday ? today : calendar.startOfDay(for: viewportStart)
        viewportStart = calendar.date(byAdding: .day, value: -half, to: anchor)!
        viewportEnd = calendar.date(byAdding: .day, value: totalDays - half, to: anchor)!
    }
}
