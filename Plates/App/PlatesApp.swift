import SwiftUI
import SwiftData
import UserNotifications

@main
struct PlatesApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var appearance = AppAppearance.shared
    let container: ModelContainer

    init() {
        container = PlatesModelContainer.make()
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .modelContainer(container)
                .environmentObject(appearance)
                .tint(PlatesColor.accent)
                .preferredColorScheme(appearance.mode.colorScheme)
        }
    }
}
