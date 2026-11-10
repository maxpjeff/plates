import SwiftData
import WidgetKit

enum WidgetReloader {
    @MainActor
    static func reloadAll(context: ModelContext) {
        let capys = (try? context.fetch(FetchDescriptor<Capybara>())) ?? []
        let settingsList = (try? context.fetch(FetchDescriptor<CapySettings>())) ?? []
        let feeds = (try? context.fetch(FetchDescriptor<Feed>())) ?? []
        guard let capy = capys.first, let settings = settingsList.first else {
            WidgetSnapshotStore.clear()
            WidgetCenter.shared.reloadAllTimelines()
            return
        }
        let rest = SharedStore.effectiveRestWeekdays(settings: settings, at: CapyClock.now())
        let feedDates = feeds.map(\.takenAt)
        let snap = WidgetSnapshotStore.build(
            name: capy.name,
            lastFeed: feedDates.max(),
            feedDates: feedDates,
            createdAt: capy.createdAt,
            restWeekdays: rest,
            streakStart: capy.currentStreakStart
        )
        WidgetSnapshotStore.save(snap)
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func clearAndReload() {
        WidgetSnapshotStore.clear()
        WidgetCenter.shared.reloadAllTimelines()
    }
}
