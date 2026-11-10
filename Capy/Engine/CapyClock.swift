import Foundation

protocol CapyClockProtocol {
    func now() -> Date
}

struct LiveClock: CapyClockProtocol {
    func now() -> Date { Date() }
}

final class DebugClock: CapyClockProtocol {
    static let shared = DebugClock()
    var offsetSeconds: TimeInterval = 0
    func now() -> Date { Date().addingTimeInterval(offsetSeconds) }
    func shift(hours: Double) { offsetSeconds += hours * 3600 }
    func reset() { offsetSeconds = 0 }
}

enum CapyClock {
    private static let lock = NSLock()
    private static var _override: CapyClockProtocol?

    static var current: CapyClockProtocol {
        lock.lock()
        defer { lock.unlock() }
        #if DEBUG
        return _override ?? DebugClock.shared
        #else
        return LiveClock()
        #endif
    }

    static func setOverride(_ clock: CapyClockProtocol?) {
        lock.lock()
        _override = clock
        lock.unlock()
    }

    static func now() -> Date { current.now() }
}
