import SwiftData
import SwiftUI
import UserNotifications

@main
struct CapyApp: App {
  @State private var appState = CapyAppState()
    private let notificationDelegate = CapyNotificationDelegate()

    var sharedModelContainer: ModelContainer = {
        do {
            return try SharedStore.modelContainer()
        } catch {
            fatalError("SwiftData: \(error)")
        }
    }()

    init() {
        CapyFontLoader.loadIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            CapyRootView()
                .environment(appState)
                .environment(\.font, CapyFont.nunito(16, .bold))
                .preferredColorScheme(.light)
                .onOpenURL { url in
                    if url == AppConstants.feedURL {
                        appState.showCamera = true
                    }
                }
                .onAppear {
                    notificationDelegate.onOpenFeed = { appState.showCamera = true }
                    UNUserNotificationCenter.current().delegate = notificationDelegate
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
