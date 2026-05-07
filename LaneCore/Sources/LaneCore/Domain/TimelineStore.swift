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

    /// Effective day width. nil = follow `granularity`. When set by zoom,
    /// `granularity` becomes informational ("none active") in the UI.
    public private(set) var customDayWidth: CGFloat? = nil

    public private(set) var viewportStart: Date
    public private(set) var viewportEnd: Date

    public var visibleGroupIds: Set<String> = []

    public static let minDayWidth: CGFloat = 6
    public static let maxDayWidth: CGFloat = 320

    private let calendar: Calendar = Calendar(identifier: .gregorian)

    public init() {
        let cal = Calendar(identifier: .gregorian)
        let today = cal.startOfDay(for: Date())
        let half = TimelineGranularity.week.defaultVisibleDays / 2
        viewportStart = cal.date(byAdding: .day, value: -half, to: today)!
        viewportEnd   = cal.date(byAdding: .day, value:  half, to: today)!
    }

    /// Effective px-per-day used for layout.
    public var effectiveDayWidth: CGFloat {
        customDayWidth ?? granularity.dayWidth
    }

    /// True when the day width still matches one of the granularity presets.
    public var isUsingPreset: Bool {
        customDayWidth == nil
    }

    public func setGranularity(_ g: TimelineGranularity) {
        granularity = g
        customDayWidth = nil
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

    /// Resize the viewport so it spans `availableWidth / effectiveDayWidth` days,
    /// keeping today centered when today is currently in view.
    public func fitTo(availableWidth: CGFloat) {
        let dayWidth = effectiveDayWidth
        guard dayWidth > 0, availableWidth > 0 else { return }
        let baseline = customDayWidth == nil ? granularity.defaultVisibleDays : 7
        let totalDays = max(baseline, Int(availableWidth / dayWidth))
        let half = totalDays / 2
        let today = calendar.startOfDay(for: Date())
        let pinnedToday = today >= viewportStart && today <= viewportEnd
        let anchor = pinnedToday ? today : calendar.startOfDay(for: viewportStart)
        viewportStart = calendar.date(byAdding: .day, value: -half, to: anchor)!
        viewportEnd = calendar.date(byAdding: .day, value: totalDays - half, to: anchor)!
    }

    /// User zoomed in/out. `factor` > 1 zooms in (wider days),
    /// < 1 zooms out (denser). Clamped to min/max.
    public func zoom(by factor: CGFloat) {
        let next = (effectiveDayWidth * factor)
            .clamped(to: Self.minDayWidth ... Self.maxDayWidth)
        customDayWidth = next
    }

    public func setDayWidth(_ width: CGFloat) {
        customDayWidth = width.clamped(to: Self.minDayWidth ... Self.maxDayWidth)
    }
}

private extension CGFloat {
    func clamped(to range: ClosedRange<CGFloat>) -> CGFloat {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
