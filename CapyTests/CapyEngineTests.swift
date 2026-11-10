import XCTest
@testable import Capy

final class CapyEngineTests: XCTestCase {
    func testTodayBarLabels() {
        var cal = Calendar.current
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        let noon = cal.date(from: DateComponents(year: 2025, month: 11, day: 11, hour: 12))!
        let input = CapyEngineInput(
            feedDates: [noon],
            createdAt: noon,
            restWeekdays: [],
            streakStart: cal.startOfDay(for: noon),
            bestStreak: 1,
            at: noon
        )
        XCTAssertEqual(CapyEngine.todayBarLabel(input: input), "Done for today")
    }
}
