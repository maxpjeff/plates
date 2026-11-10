import XCTest
@testable import Plates

final class TargetCalculatorTests: XCTestCase {
    func testHardDayTargets() {
        let settings = TargetSettings(baseKcal: 1_950, protein: 180, baseCarbs: 180, fat: 65)
        let split = SplitDay(weekday: 1, workout: "Sprints", effort: .hard)
        let t = TargetCalculator.targets(for: split, settings: settings)
        XCTAssertEqual(t.kcal, 2_250)
        XCTAssertEqual(t.carbs, 255)
        XCTAssertEqual(t.protein, 180)
        XCTAssertEqual(t.fat, 70)
    }

    func testRestDay() {
        let settings = TargetSettings()
        let split = SplitDay(weekday: 7, workout: "Rest", effort: nil)
        let t = TargetCalculator.targets(for: split, settings: settings)
        XCTAssertEqual(t.kcal, 1_950)
        XCTAssertEqual(t.carbs, 180)
    }
}
