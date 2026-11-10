import Foundation
import SwiftData

struct CapySnapshot: Equatable {
    var capyName: String
    var createdAt: Date
    var feedDates: [Date]
    var restWeekdays: Set<Int>
    var streakStart: Date?
    var bestStreak: Int
    var totalFeeds: Int
    var at: Date

    var lastFeedAt: Date? { feedDates.max() }

    var engineInput: CapyEngineInput {
        CapyEngineInput(
            feedDates: feedDates,
            createdAt: createdAt,
            restWeekdays: restWeekdays,
            streakStart: streakStart,
            bestStreak: bestStreak,
            at: at
        )
    }

    var energyRemaining: TimeInterval { CapyEngine.energyRemaining(input: engineInput) }
    var state: CapyState { CapyEngine.state(input: engineInput) }
    var streak: Int { CapyEngine.streak(input: engineInput) }

    var avatarState: AvatarState { CapyEngine.avatarState(input: engineInput) }

    var todayBarFraction: CGFloat { CapyEngine.todayBarFraction(input: engineInput) }
    var todayBarLabel: String { CapyEngine.todayBarLabel(input: engineInput) }
}

enum SharedStore {
    static func appGroupURL() -> URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppConstants.appGroupID)
    }

    static func photosDirectory() -> URL? {
        appGroupURL()?.appendingPathComponent("photos", isDirectory: true)
    }

    static func modelContainer() throws -> ModelContainer {
        let schema = Schema([Capybara.self, Feed.self, CapySettings.self])
        let config = ModelConfiguration(
            "Capy",
            schema: schema,
            isStoredInMemoryOnly: false,
            groupContainer: .identifier(AppConstants.appGroupID)
        )
        return try ModelContainer(for: schema, configurations: [config])
    }

    static func snapshot(
        capy: Capybara,
        settings: CapySettings,
        feeds: [Feed],
        at: Date = CapyClock.now()
    ) -> CapySnapshot {
        let effectiveRest = effectiveRestWeekdays(settings: settings, at: at)
        return CapySnapshot(
            capyName: capy.name,
            createdAt: capy.createdAt,
            feedDates: feeds.map(\.takenAt),
            restWeekdays: effectiveRest,
            streakStart: capy.currentStreakStart,
            bestStreak: capy.bestStreak,
            totalFeeds: capy.totalFeeds,
            at: at
        )
    }

    static func effectiveRestWeekdays(settings: CapySettings, at: Date) -> Set<Int> {
        let cal = Calendar.current
        let today = cal.startOfDay(for: at)
        if let pending = settings.pendingRestWeekdays,
           let effective = settings.pendingRestEffectiveDate,
           today >= cal.startOfDay(for: effective) {
            return Set(pending)
        }
        return Set(settings.restWeekdays)
    }

    static func applyPendingRestIfNeeded(settings: CapySettings, at: Date = CapyClock.now()) {
        guard let pending = settings.pendingRestWeekdays,
              let effective = settings.pendingRestEffectiveDate else { return }
        let cal = Calendar.current
        if cal.startOfDay(for: at) >= cal.startOfDay(for: effective) {
            settings.restWeekdays = pending
            settings.pendingRestWeekdays = nil
            settings.pendingRestEffectiveDate = nil
        }
    }

    @MainActor
    static func fetchOrCreate(in context: ModelContext) throws -> (Capybara, CapySettings) {
        let capyFetch = FetchDescriptor<Capybara>()
        let settingsFetch = FetchDescriptor<CapySettings>()
        let capys = try context.fetch(capyFetch)
        let settingsList = try context.fetch(settingsFetch)
        let capy = capys.first ?? {
            let c = Capybara()
            context.insert(c)
            return c
        }()
        let settings = settingsList.first ?? {
            let s = CapySettings()
            context.insert(s)
            return s
        }()
        return (capy, settings)
    }

    static func lastFeedDate(feeds: [Feed]) -> Date? {
        feeds.map(\.takenAt).max()
    }

    static func streakDayNumber(capy: Capybara, feedDate: Date) -> Int {
        guard let start = capy.currentStreakStart else { return 1 }
        let cal = Calendar.current
        let from = cal.startOfDay(for: start)
        let to = cal.startOfDay(for: feedDate)
        let days = cal.dateComponents([.day], from: from, to: to).day ?? 0
        return max(1, days + 1)
    }
}
