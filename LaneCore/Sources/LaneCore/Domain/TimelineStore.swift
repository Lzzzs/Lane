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

    /// Total days the canvas covers, centered on today. Wide enough that
    /// a horizontal scroll lets the user pan a year either way.
    public static let canvasRangeDays: Int = 365

    public private(set) var jumpToTodayCounter: Int = 0

    public init() {
        let cal = Calendar(identifier: .gregorian)
        let today = cal.startOfDay(for: Date())
        viewportStart = cal.date(byAdding: .day, value: -Self.canvasRangeDays, to: today)!
        viewportEnd   = cal.date(byAdding: .day, value:  Self.canvasRangeDays, to: today)!
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

    /// UI listens to `jumpToTodayCounter` via `.onChange` and scrolls to today.
    public func jumpToToday() {
        jumpToTodayCounter &+= 1
    }

    /// Re-anchor the canvas around today. The canvas is always wide enough to
    /// pan a year either way; this just resets the bounds when the date rolls
    /// over or zoom changes.
    public func reanchorAroundToday() {
        let today = calendar.startOfDay(for: Date())
        viewportStart = calendar.date(byAdding: .day, value: -Self.canvasRangeDays, to: today)!
        viewportEnd   = calendar.date(byAdding: .day, value:  Self.canvasRangeDays, to: today)!
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
