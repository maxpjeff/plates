import CoreGraphics
import Foundation

enum CapyState: String, Codable, CaseIterable {
    case lockedIn, chilling, couch, restDay, asleep, cheering, peeking

    var statusLabel: String {
        switch self {
        case .lockedIn: "Locked in"
        case .chilling: "Recovering"
        case .couch: "Lazy"
        case .restDay: "Rest day"
        case .asleep: "Chud"
        case .cheering: "Fed!"
        case .peeking: "Hey!"
        }
    }
}

struct CapyEngineInput: Equatable {
    var feedDates: [Date]
    var createdAt: Date
    var restWeekdays: Set<Int>
    var streakStart: Date?
    var bestStreak: Int
    var at: Date

    var lastFeedAt: Date? { feedDates.max() }
}

enum CapyEngine {
    // MARK: - Calendar-day status

    static func avatarState(input: CapyEngineInput) -> AvatarState {
        let cal = Calendar.current
        let wd = cal.component(.weekday, from: input.at)

        if input.restWeekdays.contains(wd) {
            return .recovering
        }

        if posted(on: input.at, feedDates: input.feedDates) {
            return .lockedIn
        }

        if streakIsLost(input: input) {
            return .streakLost
        }

        return .couchMode
    }

    static func streakIsLost(input: CapyEngineInput) -> Bool {
        let cal = Calendar.current
        let today = cal.startOfDay(for: input.at)
        guard let lastFeed = input.feedDates.max() else { return false }

        var day = cal.date(byAdding: .day, value: -1, to: today) ?? today
        let earliest = cal.startOfDay(for: input.createdAt)

        while day >= earliest {
            let wd = cal.component(.weekday, from: day)
            if input.restWeekdays.contains(wd) {
                guard let prev = cal.date(byAdding: .day, value: -1, to: day) else { break }
                day = prev
                continue
            }
            let posted = posted(on: day, feedDates: input.feedDates)
            if !posted {
                let morningAfter = cal.date(byAdding: .day, value: 1, to: day) ?? day
                if cal.startOfDay(for: lastFeed) >= morningAfter {
                    return false
                }
                return true
            }
            guard let prev = cal.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return false
    }

    static func streak(input: CapyEngineInput) -> Int {
        let cal = Calendar.current
        let today = cal.startOfDay(for: input.at)

        if streakIsLost(input: input), !posted(on: input.at, feedDates: input.feedDates) {
            return 0
        }

        var count = 0
        var day = today
        while true {
            let wd = cal.component(.weekday, from: day)
            let isRest = input.restWeekdays.contains(wd)
            let fed = posted(on: day, feedDates: input.feedDates)
            let isToday = day == today

            if isToday {
                if isRest || fed { count += 1 }
            } else {
                if isRest { count += 1 }
                else if fed { count += 1 }
                else { break }
            }

            if let start = input.streakStart, day <= cal.startOfDay(for: start), !isToday {
                break
            }
            guard let prev = cal.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return count
    }

    static func state(input: CapyEngineInput) -> CapyState {
        switch avatarState(input: input) {
        case .lockedIn: .lockedIn
        case .recovering: .restDay
        case .couchMode: .couch
        case .streakLost: .asleep
        }
    }

    /// Legacy name used by views migrating off energy — fraction 0…1 for the Today bar.
    static func todayBarFraction(input: CapyEngineInput) -> CGFloat {
        let avatar = avatarState(input: input)
        switch avatar {
        case .lockedIn, .recovering: return 1
        case .streakLost: return 0
        case .couchMode:
            let remaining = secondsUntilMidnight(at: input.at)
            return CGFloat(remaining / (24 * 3600))
        }
    }

    static func todayBarLabel(input: CapyEngineInput) -> String {
        switch avatarState(input: input) {
        case .lockedIn: return "Done for today"
        case .recovering: return "Rest day"
        case .streakLost: return "Streak lost"
        case .couchMode:
            let hrs = max(1, Int(ceil(secondsUntilMidnight(at: input.at) / 3600)))
            return "\(hrs) hrs left today"
        }
    }

    static func todayBarFillColor(for state: AvatarState) -> String {
        switch state {
        case .lockedIn: "7BC043"
        case .recovering: "7FB8DE"
        case .couchMode: "FF7A2F"
        case .streakLost: "B4B2A9"
        }
    }

    static func secondsUntilMidnight(at: Date) -> TimeInterval {
        let cal = Calendar.current
        let start = cal.startOfDay(for: at)
        guard let next = cal.date(byAdding: .day, value: 1, to: start) else { return 0 }
        return max(0, next.timeIntervalSince(at))
    }

    static func posted(on day: Date, feedDates: [Date]) -> Bool {
        let cal = Calendar.current
        return feedDates.contains { cal.isDate($0, inSameDayAs: day) }
    }

    static func todaysFeedDate(feedDates: [Date], at: Date) -> Date? {
        let cal = Calendar.current
        return feedDates.filter { cal.isDate($0, inSameDayAs: at) }.max()
    }

    static func applyFeed(
        at feedDate: Date,
        input: CapyEngineInput
    ) -> (streakStart: Date?, bestStreak: Int, totalFeedsDelta: Int) {
        let cal = Calendar.current
        let dayStart = cal.startOfDay(for: feedDate)
        var feeds = input.feedDates
        feeds.append(feedDate)

        var streakStart = input.streakStart
        let wasLost = streakIsLost(input: input) || streakStart == nil
        if wasLost {
            streakStart = dayStart
        }

        let withStart = CapyEngineInput(
            feedDates: feeds,
            createdAt: input.createdAt,
            restWeekdays: input.restWeekdays,
            streakStart: streakStart,
            bestStreak: input.bestStreak,
            at: feedDate
        )
        let newStreak = streak(input: withStart)
        let best = max(input.bestStreak, newStreak)
        return (streakStart, best, 1)
    }

    static func formatPostedTime(_ feedDate: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return "Posted at \(f.string(from: feedDate))"
    }

    // MARK: - Deprecated hour-based API (tests only if needed)

    static let capSeconds: TimeInterval = AppConstants.energyCapHours * 3600

    static func energyRemaining(input: CapyEngineInput) -> TimeInterval {
        todayBarFraction(input: input) * capSeconds
    }
}
