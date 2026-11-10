import Foundation
import SwiftData

struct HomeDayToken: Identifiable {
    let id: Date
    let weekdayLetter: String
    let style: DayTokenStyle
}

@Observable
final class HomeViewModel {
    var tick = Date()
    #if DEBUG
    var debugAvatarOverride: AvatarState?
    #endif

    func avatarState(capy: Capybara, settings: CapySettings, feeds: [Feed]) -> AvatarState {
        #if DEBUG
        if let debugAvatarOverride { return debugAvatarOverride }
        #endif
        let snap = snapshot(capy: capy, settings: settings, feeds: feeds)
        return snap.avatarState
    }

    func caption(avatar: AvatarState, feeds: [Feed]) -> String {
        switch avatar {
        case .lockedIn:
            if let feed = CapyEngine.todaysFeedDate(feedDates: feeds.map(\.takenAt), at: tick) {
                return CapyEngine.formatPostedTime(feed)
            }
            return "Done for today"
        case .recovering:
            return "Rest day. Enjoy it."
        case .couchMode:
            return "Haven't posted today"
        case .streakLost:
            return "One photo starts a new streak"
        }
    }

    func lastSevenDayTokens(
        feeds: [Feed],
        restWeekdays: Set<Int>,
        capy: Capybara
    ) -> [HomeDayToken] {
        let days = DayHistoryHelper.weekStartingSunday(containing: tick)
        return days.map { day in
            HomeDayToken(
                id: day,
                weekdayLetter: DayHistoryHelper.weekdayInitial(day),
                style: DayHistoryHelper.homeWeekStyle(
                    for: day,
                    feeds: feeds,
                    restWeekdays: restWeekdays,
                    capy: capy,
                    at: tick
                )
            )
        }
    }

    func snapshot(capy: Capybara, settings: CapySettings, feeds: [Feed]) -> CapySnapshot {
        SharedStore.snapshot(capy: capy, settings: settings, feeds: feeds, at: tick)
    }

    func refreshTick() {
        tick = CapyClock.now()
    }
}
