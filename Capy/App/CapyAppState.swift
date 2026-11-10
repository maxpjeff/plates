import Foundation
import SwiftData
import SwiftUI

@Observable
final class CapyAppState {
    var showCamera = false
    var showFed = false
    var lastFedImage: UIImage?
    var lastFedStreakDay = 1
    var lastFedWasNewStreak = false
    var showFirstFeedTip = false
    var tick = Date()

    func refreshTick() {
        tick = CapyClock.now()
    }
}
