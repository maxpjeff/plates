import Foundation
import UserNotifications

enum CapyNotifications {
    private static let noonPrefix = "capy.noon."

    static func requestAuthorization() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])) ?? false
    }

    static func reschedule(snapshot: CapySnapshot, notificationsEnabled: Bool) async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let ids = pending.map(\.identifier).filter { $0.hasPrefix(noonPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: ids)
        guard notificationsEnabled else { return }

        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized else { return }

        let cal = Calendar.current
        let today = cal.startOfDay(for: snapshot.at)

        for offset in 0..<7 {
            guard let day = cal.date(byAdding: .day, value: offset, to: today) else { continue }
            let wd = cal.component(.weekday, from: day)
            if snapshot.restWeekdays.contains(wd) { continue }

            if CapyEngine.posted(on: day, feedDates: snapshot.feedDates) { continue }

            var fire = cal.date(bySettingHour: 12, minute: 0, second: 0, of: day) ?? day
            if fire <= snapshot.at { continue }

            let content = UNMutableNotificationContent()
            content.title = "\(snapshot.capyName) is on the couch"
            content.body = "Hey, gotta get your workout in."
            content.userInfo = ["open": "feed"]

            let components = cal.dateComponents([.year, .month, .day, .hour, .minute], from: fire)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let id = "\(noonPrefix)\(offset)"
            try? await center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
        }
    }
}
