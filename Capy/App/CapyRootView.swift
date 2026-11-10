import SwiftData
import SwiftUI

struct CapyRootView: View {
    @Environment(\.modelContext) private var context
    @Query private var settingsList: [CapySettings]

    var body: some View {
        Group {
            if let settings = settingsList.first, settings.hasCompletedOnboarding {
                HomeView()
            } else {
                OnboardingFlowView()
            }
        }
        .task {
            _ = try? SharedStore.fetchOrCreate(in: context)
            WidgetReloader.reloadAll(context: context)
        }
    }
}

#Preview {
    CapyRootView()
        .modelContainer(try! SharedStore.modelContainer())
        .environment(CapyAppState())
}
