import Foundation

enum DayTokenStyle {
    case fed, rest, missed, today, asleep, scheduledRest
}

struct DayHistoryHelper {
    /// Sunday through Saturday for the week containing `date`.
    static func weekStartingSunday(containing date: Date) -> [Date] {
        var cal = Calendar.current
        cal.firstWeekday = 1
        guard let week = cal.dateInterval(of: .weekOfYear, for: date) else { return [] }
        let start = cal.startOfDay(for: week.start)
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: start) }
    }

    static func lastSevenDays(endingAt: Date) -> [Date] {
        let cal = Calendar.current
        let end = cal.startOfDay(for: endingAt)
        return (0..<7).compactMap { cal.date(byAdding: .day, value: -6 + $0, to: end) }
    }

    /// Home row: user rest weekdays show a grey ring; unlogged days stay plain.
    static func homeWeekStyle(
        for day: Date,
        feeds: [Feed],
        restWeekdays: Set<Int>,
        capy: Capybara,
        at: Date
    ) -> DayTokenStyle {
        let cal = Calendar.current
        let dayStart = cal.startOfDay(for: day)
        let todayStart = cal.startOfDay(for: at)
        let wd = cal.component(.weekday, from: day)
        let fedOnDay = feeds.contains { cal.isDate($0.takenAt, inSameDayAs: day) }

        if fedOnDay { return .fed }
        if dayStart == todayStart { return .today }
        if restWeekdays.contains(wd) { return .scheduledRest }
        if dayStart > todayStart { return .missed }

        let feedsBeforeDay = feeds.filter { $0.takenAt < day.addingTimeInterval(86400) }
        let snapAtDay = SharedStore.snapshot(
            capy: capy,
            settings: CapySettings(restWeekdays: Array(restWeekdays)),
            feeds: feedsBeforeDay,
            at: cal.date(byAdding: .hour, value: 12, to: day) ?? day
        )
        if snapAtDay.avatarState == .streakLost, dayStart < todayStart, !restWeekdays.contains(wd) { return .asleep }
        return .missed
    }

    static func style(
        for day: Date,
        feeds: [Feed],
        restWeekdays: Set<Int>,
        capy: Capybara,
        at: Date
    ) -> DayTokenStyle {
        let cal = Calendar.current
        let isToday = cal.isDate(day, inSameDayAs: at)
        let wd = cal.component(.weekday, from: day)
        let fedOnDay = feeds.contains { cal.isDate($0.takenAt, inSameDayAs: day) }

        if fedOnDay { return .fed }

        let feedsBeforeDay = feeds.filter { $0.takenAt < day.addingTimeInterval(86400) }
        let snapAtDay = SharedStore.snapshot(
            capy: capy,
            settings: CapySettings(restWeekdays: Array(restWeekdays)),
            feeds: feedsBeforeDay,
            at: cal.date(byAdding: .hour, value: 12, to: day) ?? day
        )

        if restWeekdays.contains(wd), snapAtDay.streak > 0 || capy.currentStreakStart != nil {
            return .rest
        }

        if day > cal.startOfDay(for: at) { return isToday ? .today : .missed }

        if snapAtDay.avatarState == .streakLost, !fedOnDay, day < cal.startOfDay(for: at), !restWeekdays.contains(wd) {
            return .asleep
        }

        if isToday { return .today }
        return .missed
    }

    static func weekdayInitial(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale.current
        return String(f.shortWeekdaySymbols[Calendar.current.component(.weekday, from: date) - 1].prefix(1))
    }
}
