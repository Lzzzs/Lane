import Testing
@testable import LaneCore

@Suite @MainActor
struct TimelineStoreTests {

    @Test func defaultGranularityIsWeek() {
        let store = TimelineStore()
        #expect(store.granularity == .week)
    }

    @Test func canvasContainsTodayAfterInit() {
        let store = TimelineStore()
        let cal = TestSupport.gregorianCalendar()
        let runtimeToday = cal.startOfDay(for: TestSupport.now())
        #expect(store.viewportStart <= runtimeToday)
        #expect(store.viewportEnd >= runtimeToday)
    }

    @Test func setGranularityClearsCustomZoom() {
        let store = TimelineStore()
        store.setDayWidth(40)
        #expect(store.customDayWidth != nil)
        store.setGranularity(.month)
        #expect(store.customDayWidth == nil)
        #expect(store.granularity == .month)
    }

    @Test func zoomChangesEffectiveDayWidth() {
        let store = TimelineStore()
        let original = store.effectiveDayWidth
        store.zoom(by: 2.0)
        #expect(store.effectiveDayWidth > original)
        #expect(store.isUsingPreset == false)
    }

    @Test func zoomClampsToBounds() {
        let store = TimelineStore()
        store.zoom(by: 1000)
        #expect(store.effectiveDayWidth <= TimelineStore.maxDayWidth)
        store.zoom(by: 0.0001)
        #expect(store.effectiveDayWidth >= TimelineStore.minDayWidth)
    }

    @Test func jumpToTodayBumpsCounter() {
        let store = TimelineStore()
        let before = store.jumpToTodayCounter
        store.jumpToToday()
        #expect(store.jumpToTodayCounter == before &+ 1)
    }
}
