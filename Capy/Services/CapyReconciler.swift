import Foundation
import SwiftData

enum CapyReconciler {
    @MainActor
    static func reconcile(capy: Capybara, settings: CapySettings, feeds: [Feed], at: Date = CapyClock.now()) {
        SharedStore.applyPendingRestIfNeeded(settings: settings, at: at)
        let snap = SharedStore.snapshot(capy: capy, settings: settings, feeds: feeds, at: at)
        if CapyEngine.streakIsLost(input: snap.engineInput), !CapyEngine.posted(on: at, feedDates: snap.feedDates) {
            capy.currentStreakStart = nil
        }
    }
}
