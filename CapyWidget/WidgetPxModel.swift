import Foundation

enum WidgetPxModel {
    static func build(from entry: CapyEntry) -> PxWidgetModel {
        let snap = entry.snapshot
        let weekDays = DayHistoryHelper.lastSevenDays(endingAt: entry.date)
        let letters = weekDays.map { DayHistoryHelper.weekdayInitial($0) }
        let statuses = snap?.last7Days ?? []
        let last7Kinds = zip(weekDays, statuses).map { day, status in
            let isToday = Calendar.current.isDate(day, inSameDayAs: entry.date)
            return pxDayKind(from: status, isToday: isToday)
        }
        let caption: String = {
            guard let snap else { return "" }
            switch entry.state {
            case .lockedIn:
                if let feed = CapyEngine.todaysFeedDate(feedDates: snap.feedDates, at: entry.date) {
                    return CapyEngine.formatPostedTime(feed)
                }
                return "Done for today"
            case .recovering: return "Rest day. Enjoy it."
            case .couchMode: return "Haven't posted today"
            case .streakLost: return "One photo starts a new streak"
            }
        }()
        return PxWidgetModel(
            name: entry.name,
            status: PxStatus(entry.state),
            streak: entry.streak,
            todayFraction: Double(entry.todayFraction),
            shortText: shortText(avatar: entry.state, at: entry.date),
            caption: caption,
            last7: last7Kinds,
            last7Letters: letters
        )
    }

    private static func pxDayKind(from status: DayStatus, isToday: Bool) -> PxDayKind {
        switch status {
        case .fed: return isToday ? .todayPosted : .posted
        case .rest: return .rest
        case .missed: return .missed
        case .today: return .today
        }
    }

    private static func shortText(avatar: AvatarState, at: Date) -> String {
        switch avatar {
        case .lockedIn: return "DONE"
        case .recovering: return "REST"
        case .streakLost: return "LOST"
        case .couchMode:
            let hrs = max(1, Int(ceil(CapyEngine.secondsUntilMidnight(at: at) / 3600)))
            return "\(hrs)H"
        }
    }
}
