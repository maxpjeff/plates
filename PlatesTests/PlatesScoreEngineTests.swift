import XCTest
@testable import Plates

final class PlatesScoreEngineTests: XCTestCase {
    func testFullDayWithGoal() {
        let score = PlatesScoreEngine.dailyScore(DailyScoreInput(
            sessionLogged: true,
            goalSetAndReflected: true,
            goalHit: true,
            proteinTargetHit: true,
            mealsLogged: true,
            hasSessionGoal: true,
            isRestDay: false
        ))
        XCTAssertEqual(score, 100)
    }

    func testRestDayWithoutGoal() {
        let score = PlatesScoreEngine.dailyScore(DailyScoreInput(
            sessionLogged: false,
            goalSetAndReflected: false,
            goalHit: false,
            proteinTargetHit: true,
            mealsLogged: true,
            hasSessionGoal: false,
            isRestDay: true
        ))
        XCTAssertEqual(score, 100)
    }
}
