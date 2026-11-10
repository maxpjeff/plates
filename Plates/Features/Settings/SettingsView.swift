import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var profile: UserProfile

    var body: some View {
        NavigationStack {
            Form {
                Section("Profile") {
                    TextField("Name", text: $profile.name)
                    Picker("Units", selection: $profile.unitsRaw) {
                        ForEach(WeightUnit.allCases, id: \.rawValue) { Text($0.rawValue.uppercased()).tag($0.rawValue) }
                    }
                }
                Section("Goals") {
                    ForEach(Goal.allCases) { goal in
                        Toggle(goal.label, isOn: binding(for: goal))
                    }
                }
                Section("Training") {
                    NavigationLink("Lift library & routines") {
                        LiftRootView()
                    }
                }
                Section("Notifications") {
                    Toggle("Reflect nudge", isOn: reflectBinding)
                    Toggle("Tomorrow look-ahead", isOn: lookAheadBinding)
                }
                Section("Detail") {
                    Picker("Food detail", selection: $profile.foodDetailRaw) {
                        ForEach(DetailLevel.allCases, id: \.rawValue) { Text($0.rawValue).tag($0.rawValue) }
                    }
                    Picker("Training detail", selection: $profile.trainingDetailRaw) {
                        ForEach(DetailLevel.allCases, id: \.rawValue) { Text($0.rawValue).tag($0.rawValue) }
                    }
                    if profile.foodDetail == .dialedIn {
                        Stepper("Protein g/kg: \(profile.proteinPerKg, specifier: "%.1f")", value: $profile.proteinPerKg, in: 1.2...2.6, step: 0.1)
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var reflectBinding: Binding<Bool> {
        Binding(
            get: { PlatesNotificationPreferences.reflectEnabled },
            set: { PlatesNotificationPreferences.reflectEnabled = $0 }
        )
    }

    private var lookAheadBinding: Binding<Bool> {
        Binding(
            get: { PlatesNotificationPreferences.lookAheadEnabled },
            set: { PlatesNotificationPreferences.lookAheadEnabled = $0 }
        )
    }

    private func binding(for goal: Goal) -> Binding<Bool> {
        Binding(
            get: { profile.goals.contains(goal) },
            set: { on in
                var g = profile.goals
                if on { g.append(goal) } else { g.removeAll { $0 == goal } }
                profile.goalsRaw = g.map(\.rawValue)
            }
        )
    }
}
