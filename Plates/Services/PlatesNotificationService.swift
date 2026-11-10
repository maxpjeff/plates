import Foundation
import UserNotifications

enum PlatesNotificationKind: String {
    case reflectNudge = "plates.reflect"
    case lookAhead = "plates.lookAhead"
}

enum PlatesNotificationPreferences {
    static let reflectKey = "plates.notify.reflect"
    static let lookAheadKey = "plates.notify.lookAhead"

    static var reflectEnabled: Bool {
        get { UserDefaults.standard.object(forKey: reflectKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: reflectKey) }
    }

    static var lookAheadEnabled: Bool {
        get { UserDefaults.standard.object(forKey: lookAheadKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: lookAheadKey) }
    }
}

@MainActor
enum PlatesNotificationService {
    static func requestAuthorizationIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        _ = try? await center.requestAuthorization(options: [.alert, .sound])
    }

    /// Reflect nudge: 3 h after session logged, unless after 9 PM → 8 PM same day or skip.
    static func scheduleReflectNudge(
        sessionTitle: String,
        mainBlockLabel: String?,
        loggedAt: Date
    ) {
        guard PlatesNotificationPreferences.reflectEnabled else { return }
        cancel(kind: .reflectNudge)

        let calendar = Calendar.current
        var fire = calendar.date(byAdding: .hour, value: 3, to: loggedAt) ?? loggedAt
        let hour = calendar.component(.hour, from: fire)
        if hour >= 21 {
            var comps = calendar.dateComponents([.year, .month, .day], from: loggedAt)
            comps.hour = 20
            comps.minute = 0
            if let eightPM = calendar.date(from: comps), eightPM > loggedAt {
                fire = eightPM
            } else {
                return
            }
        }

        let body: String
        if let mainBlockLabel {
            body = "How did those \(mainBlockLabel.lowercased()) feel? Take a minute to reflect on \(sessionTitle)."
        } else {
            body = "Hey, did you reflect on today's workout?"
        }

        schedule(
            kind: .reflectNudge,
            title: "Plates",
            body: body,
            at: fire,
            userInfo: ["target": "reflect"]
        )
    }

    /// Look-ahead: 7:30 PM evening before a planned session with no Before entry.
    static func scheduleLookAhead(sessionTitle: String, sessionDate: Date) {
        guard PlatesNotificationPreferences.lookAheadEnabled else { return }
        cancel(kind: .lookAhead)

        let calendar = Calendar.current
        guard let dayBefore = calendar.date(byAdding: .day, value: -1, to: sessionDate) else { return }
        var comps = calendar.dateComponents([.year, .month, .day], from: dayBefore)
        comps.hour = 19
        comps.minute = 30
        guard let fire = calendar.date(from: comps) else { return }

        schedule(
            kind: .lookAhead,
            title: "Plates",
            body: "Tomorrow: \(sessionTitle). Want to set a goal?",
            at: fire,
            userInfo: ["target": "before"]
        )
    }

    static func cancel(kind: PlatesNotificationKind) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [kind.rawValue])
    }

    private static func schedule(kind: PlatesNotificationKind, title: String, body: String, at date: Date, userInfo: [String: String]) {
        guard date > Date() else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.userInfo = userInfo

        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: kind.rawValue, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
