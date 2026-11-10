import SwiftUI
import SwiftData

struct AppRootView: View {
    @Environment(\.modelContext) private var context
    @Query private var profiles: [UserProfile]

    var body: some View {
        V2RootView()
            .task {
                ensureProfile(context: context)
            }
    }

    private func ensureProfile(context: ModelContext) {
        if (try? context.fetch(FetchDescriptor<UserProfile>()))?.isEmpty ?? true {
            context.insert(UserProfile(name: "Alex", onboardingComplete: true))
        } else if let profile = try? context.fetch(FetchDescriptor<UserProfile>()).first {
            profile.onboardingComplete = true
        }
        try? context.save()
    }
}

#Preview {
    AppRootView()
        .modelContainer(SampleData.previewContainer())
}
