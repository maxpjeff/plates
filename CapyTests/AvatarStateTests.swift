import XCTest
@testable import Capy

final class AvatarStateTests: XCTestCase {
    func testStreakLostLabelIsChud() {
        XCTAssertEqual(AvatarState.streakLost.label, "Chud")
    }
}
