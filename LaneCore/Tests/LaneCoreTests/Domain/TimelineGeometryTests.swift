import Testing
@testable import LaneCore

@Suite struct TimelineGeometryTests {

    @Test func xForDateGivesCorrectOffset() {
        let start = TestSupport.date(2026, 5, 1)
        let geo = TimelineGeometry(viewportStart: start, dayWidth: 64)
        let day4 = TestSupport.date(2026, 5, 4)
        // 3 days from start * 64
        #expect(abs(geo.x(for: day4) - 64 * 3) < 0.5)
    }

    @Test func widthBetweenInclusive() {
        let start = TestSupport.date(2026, 5, 1)
        let geo = TimelineGeometry(viewportStart: start, dayWidth: 64)
        let end = TestSupport.date(2026, 5, 5)
        // 5 days inclusive (5/1 .. 5/5) * 64
        #expect(abs(geo.width(from: start, to: end) - 64 * 5) < 0.5)
    }

    @Test func progressForActiveStage() {
        let start = TestSupport.date(2026, 5, 1)
        let end = TestSupport.date(2026, 5, 5)
        let today = TestSupport.date(2026, 5, 3)
        // 2 days elapsed of 4 total → 0.5
        #expect(abs(TimelineGeometry.progress(start: start, end: end, today: today) - 0.5) < 0.01)
    }

    @Test func progressClampsAtEndpoints() {
        let start = TestSupport.date(2026, 5, 1)
        let end = TestSupport.date(2026, 5, 5)
        #expect(TimelineGeometry.progress(start: start, end: end,
                                          today: TestSupport.date(2026, 4, 30)) == 0)
        #expect(TimelineGeometry.progress(start: start, end: end,
                                          today: TestSupport.date(2026, 5, 6)) == 1)
    }

    @Test func quantizeRoundsToFifths() {
        #expect(TimelineGeometry.quantize(0.13) == 0.0)
        #expect(TimelineGeometry.quantize(0.30) == 0.25)
        #expect(TimelineGeometry.quantize(0.55) == 0.50)
        #expect(TimelineGeometry.quantize(0.80) == 0.75)
        #expect(TimelineGeometry.quantize(0.95) == 1.00)
    }
}
