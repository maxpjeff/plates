import Foundation

/// Visual capybara phase from hours since the last feed (rest days still advance clock time).
enum CapyMascotPhase: String, CaseIterable {
    case lockedIn
    case recovering
    case couch
    case streakLost

    var imageName: String {
        switch self {
        case .lockedIn: "MascotLockedIn"
        case .recovering: "MascotChilling"
        case .couch: "MascotCouch"
        case .streakLost: "MascotAsleep"
        }
    }

    var statusLabel: String {
        switch self {
        case .lockedIn: "Locked in"
        case .recovering: "Recovering"
        case .couch: "Couch mode"
        case .streakLost: "Streak lost"
        }
    }

    /// - Locked in: feed within 12h
    /// - Recovering: 12–24h
    /// - Couch mode: 24–48h
    /// - Streak lost: 48h+
    static func phase(lastFeedAt: Date?, at: Date = CapyClock.now()) -> CapyMascotPhase {
        guard let lastFeedAt else { return .lockedIn }
        let hours = at.timeIntervalSince(lastFeedAt) / 3600
        if hours < 12 { return .lockedIn }
        if hours < 24 { return .recovering }
        if hours < 48 { return .couch }
        return .streakLost
    }

    /// Maps to legacy `CapyState` for energy bar colors and widgets.
    var engineState: CapyState {
        switch self {
        case .lockedIn: .lockedIn
        case .recovering: .chilling
        case .couch: .couch
        case .streakLost: .asleep
        }
    }
}
