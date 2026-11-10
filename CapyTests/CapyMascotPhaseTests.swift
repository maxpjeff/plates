import XCTest
@testable import Capy

final class CapyMascotPhaseTests: XCTestCase {
    func testPhaseBoundaries() {
        let feed = Date()
        XCTAssertEqual(CapyMascotPhase.phase(lastFeedAt: feed, at: feed.addingTimeInterval(11 * 3600)), .lockedIn)
        XCTAssertEqual(CapyMascotPhase.phase(lastFeedAt: feed, at: feed.addingTimeInterval(12 * 3600)), .recovering)
        XCTAssertEqual(CapyMascotPhase.phase(lastFeedAt: feed, at: feed.addingTimeInterval(23 * 3600)), .recovering)
        XCTAssertEqual(CapyMascotPhase.phase(lastFeedAt: feed, at: feed.addingTimeInterval(24 * 3600)), .couch)
        XCTAssertEqual(CapyMascotPhase.phase(lastFeedAt: feed, at: feed.addingTimeInterval(47 * 3600)), .couch)
        XCTAssertEqual(CapyMascotPhase.phase(lastFeedAt: feed, at: feed.addingTimeInterval(48 * 3600)), .streakLost)
    }

    func testNoFeedDefaultsLockedIn() {
        XCTAssertEqual(CapyMascotPhase.phase(lastFeedAt: nil), .lockedIn)
    }
}
