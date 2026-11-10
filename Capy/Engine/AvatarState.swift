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
        case .couchMode: "Couch mode"
        case .streakLost: "Chud"
        }
    }

    var sceneColor: Color {
        switch self {
        case .lockedIn: Color(capyHex: "E6F4D7")
        case .recovering: Color(capyHex: "FBE7BE")
        case .couchMode: Color(capyHex: "E3DAF2")
        case .streakLost: Color(capyHex: "F8D5D9")
        }
    }

    var sceneDotColor: Color {
        switch self {
        case .lockedIn: Color(capyHex: "C8E4B0")
        case .recovering: Color(capyHex: "E8CF9A")
        case .couchMode: Color(capyHex: "C8B8E0")
        case .streakLost: Color(capyHex: "E8B8C0")
        }
    }

    var pillColor: Color {
        switch self {
        case .lockedIn: Color(capyHex: "CFEFB4")
        case .recovering: Color(capyHex: "FFD08A")
        case .couchMode: Color(capyHex: "E3DAF2")
        case .streakLost: Color(capyHex: "F8D5D9")
        }
    }

    var pillTextColor: Color {
        switch self {
        case .lockedIn: Color(capyHex: "1F4A0B")
        case .recovering: Color(capyHex: "5A2A04")
        case .couchMode: Color(capyHex: "3C2A6B")
        case .streakLost: Color(capyHex: "7A1F2B")
        }
    }

    var todayBarTextColor: Color {
        switch self {
        case .lockedIn: Color(capyHex: "1F4A0B")
        case .recovering: Color(capyHex: "0D3B5C")
        case .couchMode: Theme.Color.flame
        case .streakLost: Color(capyHex: "B4B2A9")
        }
    }

    var todayBarFillColor: Color {
        Color(capyHex: CapyEngine.todayBarFillColor(for: self))
    }

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
        case .couchMode: "Get \(name) off the couch"
        case .streakLost: "Wake \(name) up"
        }
    }
}
