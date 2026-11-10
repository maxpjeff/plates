import Foundation
import SwiftData

@Model
final class Capybara {
    @Attribute(.unique) var id: UUID
    var name: String
    var createdAt: Date
    var currentStreakStart: Date?
    var bestStreak: Int
    var totalFeeds: Int

    init(
        id: UUID = UUID(),
        name: String = "Biscuit",
        createdAt: Date = Date(),
        currentStreakStart: Date? = nil,
        bestStreak: Int = 0,
        totalFeeds: Int = 0
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.currentStreakStart = currentStreakStart
        self.bestStreak = bestStreak
        self.totalFeeds = totalFeeds
    }
}

@Model
final class Feed {
    @Attribute(.unique) var id: UUID
    var takenAt: Date
    var photoFilename: String
    var streakDay: Int

    init(id: UUID = UUID(), takenAt: Date = Date(), photoFilename: String, streakDay: Int) {
        self.id = id
        self.takenAt = takenAt
        self.photoFilename = photoFilename
        self.streakDay = streakDay
    }
}

@Model
final class CapySettings {
    @Attribute(.unique) var id: UUID
    var restWeekdays: [Int]
    var pendingRestWeekdays: [Int]?
    var pendingRestEffectiveDate: Date?
    var notificationsEnabled: Bool
    var hasCompletedOnboarding: Bool

    init(
        id: UUID = UUID(),
        restWeekdays: [Int] = [1],
        pendingRestWeekdays: [Int]? = nil,
        pendingRestEffectiveDate: Date? = nil,
        notificationsEnabled: Bool = false,
        hasCompletedOnboarding: Bool = false
    ) {
        self.id = id
        self.restWeekdays = restWeekdays
        self.pendingRestWeekdays = pendingRestWeekdays
        self.pendingRestEffectiveDate = pendingRestEffectiveDate
        self.notificationsEnabled = notificationsEnabled
        self.hasCompletedOnboarding = hasCompletedOnboarding
    }
}
