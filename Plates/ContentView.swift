import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "calendar")
                }

            NavigationStack {
                PlaceholderTab(title: "Meals", systemImage: "fork.knife")
            }
            .tabItem {
                Label("Meals", systemImage: "fork.knife")
            }

            NavigationStack {
                PlaceholderTab(title: "Workouts", systemImage: "figure.strengthtraining.traditional")
            }
            .tabItem {
                Label("Workouts", systemImage: "figure.strengthtraining.traditional")
            }

            NavigationStack {
                PlaceholderTab(title: "Profile", systemImage: "person.crop.circle")
            }
            .tabItem {
                Label("Profile", systemImage: "person.crop.circle")
            }
        }
    }
}

private struct TodayView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Meals") {
                    Text("Log meals for today")
                        .foregroundStyle(.secondary)
                }
                Section("Workouts") {
                    Text("Log workouts for today")
                        .foregroundStyle(.secondary)
                }

                if !SupabaseConfig.isConfigured {
                    Section("Backend") {
                        Text("Add Supabase keys in Config/Secrets.xcconfig (see Secrets.example.xcconfig).")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Today")
        }
    }
}

private struct PlaceholderTab: View {
    let title: String
    let systemImage: String

    var body: some View {
        ContentUnavailableView(
            title,
            systemImage: systemImage,
            description: Text("Coming soon")
        )
        .navigationTitle(title)
    }
}

#Preview {
    ContentView()
}
