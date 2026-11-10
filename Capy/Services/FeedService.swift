import SwiftData
import UIKit

enum FeedService {
    @MainActor
    static func recordFeed(
        image: UIImage,
        context: ModelContext,
        capy: Capybara,
        settings: CapySettings
    ) throws -> (streakDay: Int, newStreak: Bool) {
        let at = CapyClock.now()
        var feeds = try context.fetch(FetchDescriptor<Feed>())
        CapyReconciler.reconcile(capy: capy, settings: settings, feeds: feeds, at: at)

        let snapBefore = SharedStore.snapshot(capy: capy, settings: settings, feeds: feeds, at: at)
        let wasLost = snapBefore.avatarState == .streakLost
        let startingFresh = wasLost || capy.currentStreakStart == nil

        let filename = try PhotoStore.saveJPEG(image)
        let apply = CapyEngine.applyFeed(at: at, input: snapBefore.engineInput)

        if let newStart = apply.streakStart {
            capy.currentStreakStart = newStart
        }

        capy.bestStreak = apply.bestStreak
        capy.totalFeeds += 1

        let streakDay = SharedStore.streakDayNumber(capy: capy, feedDate: at)
        let feed = Feed(takenAt: at, photoFilename: filename, streakDay: streakDay)
        context.insert(feed)
        try context.save()

        feeds = try context.fetch(FetchDescriptor<Feed>())
        let snapAfter = SharedStore.snapshot(capy: capy, settings: settings, feeds: feeds, at: at)
        Task {
            await CapyNotifications.reschedule(snapshot: snapAfter, notificationsEnabled: settings.notificationsEnabled)
        }
        WidgetReloader.reloadAll(context: context)

        return (streakDay, startingFresh || capy.totalFeeds == 1)
    }
}
