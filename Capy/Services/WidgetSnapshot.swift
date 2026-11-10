import Foundation

enum DayStatus: String, Codable, Equatable {
    case fed, rest, missed, today
}

struct WidgetSnapshot: Codable, Equatable {
    var name: String
    var lastFeedDate: Date?
    var feedDates: [Date]
    var restWeekdays: [Int]
    var streakStart: Date?
    var createdAt: Date
    var last7Days: [DayStatus]

    func engineInput(at: Date) -> CapyEngineInput {
        CapyEngineInput(
            feedDates: feedDates,
            createdAt: createdAt,
            restWeekdays: Set(restWeekdays),
            streakStart: streakStart,
            bestStreak: 0,
            at: at
        )
    }
}

enum WidgetSnapshotStore {
    static let key = "widgetSnapshot"

    static func save(_ snapshot: WidgetSnapshot) {
        guard let defaults = UserDefaults(suiteName: AppConstants.appGroupID) else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(snapshot) else { return }
        defaults.set(data, forKey: key)
    }

    static func load() -> WidgetSnapshot? {
        guard let defaults = UserDefaults(suiteName: AppConstants.appGroupID),
              let data = defaults.data(forKey: key)
        else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let snap = try? decoder.decode(WidgetSnapshot.self, from: data) {
            return snap
        }
        return try? decoder.decode(LegacyWidgetSnapshot.self, from: data).migrated
    }

    static func clear() {
        UserDefaults(suiteName: AppConstants.appGroupID)?.removeObject(forKey: key)
    }

    static func build(
        name: String,
        lastFeed: Date?,
        feedDates: [Date],
        createdAt: Date,
        restWeekdays: Set<Int>,
        streakStart: Date?,
        at: Date = CapyClock.now()
    ) -> WidgetSnapshot {
        let days = DayHistoryHelper.lastSevenDays(endingAt: at)
        let cal = Calendar.current
        let rest = restWeekdays
        let streakAlive = streakStart != nil && lastFeed != nil
        let statuses: [DayStatus] = days.map { day in
            let fed = feedDates.contains { cal.isDate($0, inSameDayAs: day) }
            if fed { return .fed }
            if cal.isDate(day, inSameDayAs: at) { return .today }
            let wd = cal.component(.weekday, from: day)
            if rest.contains(wd), streakAlive { return .rest }
            return .missed
        }
        return WidgetSnapshot(
            name: name,
            lastFeedDate: lastFeed,
            feedDates: feedDates,
            restWeekdays: Array(rest).sorted(),
            streakStart: streakStart,
            createdAt: createdAt,
            last7Days: statuses
        )
    }
}

private struct LegacyWidgetSnapshot: Codable {
    var name: String
    var lastFeedDate: Date?
    var restWeekdays: [Int]
    var streakStart: Date?
    var last7Days: [DayStatus]

    var migrated: WidgetSnapshot {
        WidgetSnapshot(
            name: name,
            lastFeedDate: lastFeedDate,
            feedDates: lastFeedDate.map { [$0] } ?? [],
            restWeekdays: restWeekdays,
            streakStart: streakStart,
            createdAt: lastFeedDate ?? Date(),
            last7Days: last7Days
        )
    }
}
