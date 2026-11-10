import Foundation
import UserNotifications

extension Notification.Name {
    static let platesOpenTodayJournal = Notification.Name("plates.openTodayJournal")
}

final class PlatesNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let target = response.notification.request.content.userInfo["target"] as? String ?? "reflect"
        NotificationCenter.default.post(
            name: .platesOpenTodayJournal,
            object: nil,
            userInfo: ["target": target]
        )
        completionHandler()
    }
}
