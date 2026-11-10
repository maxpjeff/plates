import XCTest
@testable import Plates

final class PlatesTests: XCTestCase {
    func testGoalLabels() {
        XCTAssertEqual(Goal.buildMuscle.label, "Build muscle")
    }
}
