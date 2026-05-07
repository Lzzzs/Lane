import Testing
@testable import LaneCore

@Suite @MainActor
struct TimelineStoreTests {

    @Test func defaultGranularityIsWeek() {
        let store = TimelineStore()
        #expect(store.granularity == .week)
    }

    @Test func jumpToTodayKeepsTodayInRange() {
        let store = TimelineStore()
        let today = TestSupport.date(2026, 5, 6)
        // Don't pin "today" — just verify the runtime today is within the viewport.
        store.jumpToToday()
        // Use system "today" since jumpToToday uses Date()
        let cal = TestSupport.gregorianCalendar()
        let runtimeToday = cal.startOfDay(for: TestSupport.now())
        #expect(store.viewportStart <= runtimeToday)
        #expect(store.viewportEnd >= runtimeToday)
        _ = today
    }

    @Test func setGranularityKeepsTodayInRange() {
        let store = TimelineStore()
        store.setGranularity(.month)
        let cal = TestSupport.gregorianCalendar()
        let runtimeToday = cal.startOfDay(for: TestSupport.now())
        #expect(store.viewportStart <= runtimeToday)
        #expect(store.viewportEnd >= runtimeToday)
    }

    @Test func scrollByDaysShiftsViewport() {
        let store = TimelineStore()
        let originalStart = store.viewportStart
        store.scroll(byDays: 7)
        let cal = TestSupport.gregorianCalendar()
        let expected = cal.date(byAdding: .day, value: 7, to: originalStart)!
        #expect(store.viewportStart == expected)
    }
}
