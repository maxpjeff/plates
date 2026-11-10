import SwiftUI

enum PxModelBuilder {
    static func homeModel(
        capy: Capybara,
        snap: CapySnapshot,
        avatar: AvatarState,
        caption: String,
        todayFraction: Double,
        todayText: String,
        dayTokens: [HomeDayToken],
        at: Date
    ) -> PxHomeModel {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        let cal = Calendar.current
        let last7 = dayTokens.map { token in
            let isToday = cal.isDate(token.id, inSameDayAs: at)
            return PxDay(letter: token.weekdayLetter, kind: pxDayKind(token.style, isToday: isToday))
        }
        return PxHomeModel(
            name: capy.name,
            dateLine: f.string(from: at),
            status: PxStatus(avatar),
            streak: snap.streak,
            caption: caption,
            todayFraction: todayFraction,
            todayText: todayText,
            last7: last7
        )
    }

    static func pxDayKind(_ style: DayTokenStyle, isToday: Bool) -> PxDayKind {
        switch style {
        case .fed: return isToday ? .todayPosted : .posted
        case .rest, .scheduledRest: return .rest
        case .missed, .asleep: return .missed
        case .today: return .today
        }
    }

    static func fedSubtitle(
        newStreak: Bool,
        settings: CapySettings,
        at: Date = CapyClock.now()
    ) -> String {
        if newStreak { return "Day 1. New streak started." }
        let cal = Calendar.current
        let tomorrow = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: at)) ?? at
        let wd = cal.component(.weekday, from: tomorrow)
        let rest = SharedStore.effectiveRestWeekdays(settings: settings, at: tomorrow)
        if rest.contains(wd) {
            return "Locked in. Enjoy your rest day tomorrow."
        }
        return "Locked in for today. See you tomorrow."
    }

    static func historyModel(
        capy: Capybara,
        snap: CapySnapshot,
        monthAnchor: Date,
        feedsInMonth: [Feed],
        allFeeds: [Feed],
        settings: CapySettings,
        at: Date
    ) -> PxHistoryModel {
        let cal = Calendar.current
        let monthName: String = {
            let f = DateFormatter()
            f.dateFormat = "MMMM"
            return f.string(from: monthAnchor)
        }()
        let rest = SharedStore.effectiveRestWeekdays(settings: settings, at: monthAnchor)
        let daysInMonth = daysInMonth(monthAnchor)
        let leading = leadingBlankCells(monthAnchor)
        let todayStart = cal.startOfDay(for: at)
        let dayKinds = daysInMonth.map { day -> PxDayKind in
            let dayStart = cal.startOfDay(for: day)
            if dayStart > todayStart { return .future }
            let style = DayHistoryHelper.style(
                for: day,
                feeds: allFeeds,
                restWeekdays: rest,
                capy: capy,
                at: at
            )
            let isToday = cal.isDate(day, inSameDayAs: at)
            return pxDayKind(style, isToday: isToday)
        }

        let recent: [PxRecentFeed] = allFeeds.prefix(12).map { feed in
            let label: String = {
                if cal.isDateInToday(feed.takenAt) { return "Today" }
                let f = DateFormatter()
                f.dateFormat = "EEE"
                return f.string(from: feed.takenAt)
            }()
            let photo: Image? = PhotoStore.load(filename: feed.photoFilename).map { Image(uiImage: $0) }
            return PxRecentFeed(photo: photo, label: label)
        }

        return PxHistoryModel(
            streak: snap.streak,
            best: capy.bestStreak,
            totalFeeds: capy.totalFeeds,
            monthTitle: monthName,
            monthFeeds: feedsInMonth.count,
            leadingBlanks: leading,
            days: dayKinds,
            recent: recent
        )
    }

    private static func daysInMonth(_ date: Date) -> [Date] {
        let cal = Calendar.current
        guard let range = cal.range(of: .day, in: .month, for: date),
              let start = cal.date(from: cal.dateComponents([.year, .month], from: date))
        else { return [] }
        return range.compactMap { cal.date(byAdding: .day, value: $0 - 1, to: start) }
    }

    private static func leadingBlankCells(_ monthAnchor: Date) -> Int {
        let cal = Calendar.current
        guard let start = cal.date(from: cal.dateComponents([.year, .month], from: monthAnchor)) else { return 0 }
        let wd = cal.component(.weekday, from: start)
        return (wd - cal.firstWeekday + 7) % 7
    }
}
