import XCTest
@testable import Capy

final class CapyDayStatusTests: XCTestCase {
    private var cal: Calendar!

    override func setUp() {
        super.setUp()
        cal = Calendar.current
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
    }

    func testRestDayIsRecoveringEvenWithPost() {
        // Sunday rest, posted Sunday morning
        let sunday = date(2025, 11, 9, 10)
        let input = input(
            at: sunday,
            feeds: [sunday],
            rest: [1] // Sunday
        )
        XCTAssertEqual(CapyEngine.avatarState(input: input), .recovering)
    }

    func testWorkoutDayBeforePostingIsCouchMode() {
        let tuesday = date(2025, 11, 11, 15)
        let monday = date(2025, 11, 10, 18)
        let input = input(at: tuesday, feeds: [monday], rest: [1])
        XCTAssertEqual(CapyEngine.avatarState(input: input), .couchMode)
    }

    func testPostingGivesLockedIn() {
        let today = date(2025, 11, 11, 14)
        let input = input(at: today, feeds: [today], rest: [1], start: date(2025, 11, 1, 12))
        XCTAssertEqual(CapyEngine.avatarState(input: input), .lockedIn)
    }

    func testMissedWorkoutDayShowsStreakLostNextDay() {
        let monday = date(2025, 11, 10, 18)
        let tuesday = date(2025, 11, 11, 9)
        let input = input(at: tuesday, feeds: [monday], rest: [1])
        XCTAssertEqual(CapyEngine.avatarState(input: input), .streakLost)
        XCTAssertEqual(AvatarState.from(input: input).label, "Chud")
    }

    func testPostAfterLossRestartsStreakAtDayOne() {
        let monday = date(2025, 11, 10, 18)
        let wednesday = date(2025, 11, 12, 10)
        let inputBefore = input(at: date(2025, 11, 11, 12), feeds: [monday], rest: [1])
        XCTAssertTrue(CapyEngine.streakIsLost(input: inputBefore))

        let apply = CapyEngine.applyFeed(
            at: wednesday,
            input: inputBefore
        )
        XCTAssertEqual(apply.streakStart, cal.startOfDay(for: wednesday))

        let inputAfter = CapyEngineInput(
            feedDates: [monday, wednesday],
            createdAt: monday,
            restWeekdays: [1],
            streakStart: apply.streakStart,
            bestStreak: 1,
            at: wednesday
        )
        XCTAssertEqual(CapyEngine.avatarState(input: inputAfter), .lockedIn)
        XCTAssertEqual(CapyEngine.streak(input: inputAfter), 1)
    }

    func testRestDaysInStreakDoNotBreakCount() {
        let fri = date(2025, 11, 7, 12)
        let sat = date(2025, 11, 8, 12) // rest
        let sun = date(2025, 11, 9, 12) // rest in some configs — use Saturday rest only
        let input = CapyEngineInput(
            feedDates: [fri, sun],
            createdAt: fri,
            restWeekdays: [7], // Saturday
            streakStart: cal.startOfDay(for: fri),
            bestStreak: 0,
            at: sun
        )
        XCTAssertEqual(CapyEngine.streak(input: input), 3)
    }

    private func input(
        at: Date,
        feeds: [Date],
        rest: Set<Int>,
        start: Date? = nil
    ) -> CapyEngineInput {
        CapyEngineInput(
            feedDates: feeds,
            createdAt: feeds.min() ?? at,
            restWeekdays: rest,
            streakStart: start ?? (feeds.isEmpty ? nil : cal.startOfDay(for: feeds.min()!)),
            bestStreak: 0,
            at: at
        )
    }

    private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int) -> Date {
        cal.date(from: DateComponents(year: y, month: m, day: d, hour: h))!
    }
}
