import SwiftUI

enum AvatarState: String, CaseIterable, Equatable {
    case lockedIn
    case recovering
    case couchMode
    case streakLost

    static func from(input: CapyEngineInput) -> AvatarState {
        CapyEngine.avatarState(input: input)
    }

    static func from(
        feedDates: [Date],
        restWeekdays: Set<Int>,
        streakStart: Date?,
        createdAt: Date,
        at: Date = CapyClock.now()
    ) -> AvatarState {
        from(
            input: CapyEngineInput(
                feedDates: feedDates,
                createdAt: createdAt,
                restWeekdays: restWeekdays,
                streakStart: streakStart,
                bestStreak: 0,
                at: at
            )
        )
    }

    var imageName: String {
        switch self {
        case .lockedIn: "capy_locked_in"
        case .recovering: "capy_recovering"
        case .couchMode: "capy_couch_mode"
        case .streakLost: "capy_streak_lost"
        }
    }

    var tintImageName: String {
        switch self {
        case .lockedIn: "capy_locked_in_tint"
        case .recovering: "capy_recovering_tint"
        case .couchMode: "capy_couch_mode_tint"
        case .streakLost: "capy_streak_lost_tint"
        }
    }

    var label: String {
        switch self {
        case .lockedIn: "Locked in"
        case .recovering: "Recovering"
        case .couchMode: "Lazy"
        case .streakLost: "Chud"
        }
    }

    var sceneColor: Color { PxStatus(self).sceneColor }
    var sceneDotColor: Color { PxStatus(self).sceneGrid }
    var pillColor: Color { PxStatus(self).pillColor }
    var pillTextColor: Color { PxStatus(self).pillText }
    var todayBarTextColor: Color { PxStatus(self).accentText }
    var todayBarFillColor: Color { PxStatus(self).barColor }

    var engineState: CapyState {
        switch self {
        case .lockedIn: .lockedIn
        case .recovering: .chilling
        case .couchMode: .couch
        case .streakLost: .asleep
        }
    }

    func feedButtonTitle(name: String) -> String {
        switch self {
        case .lockedIn, .recovering: "Feed \(name)"
        case .couchMode: "Get \(name) moving"
        case .streakLost: "Wake \(name) up"
        }
    }
}
