import SwiftUI
import SwiftData

struct V2RootView: View {
    @Environment(\.modelContext) private var context
    @Query private var profiles: [UserProfile]
    @State private var store = FuelStore()
    @State private var tab: V2Tab = .fuel
    @AppStorage("v2.lastCheckInDay") private var lastCheckInDay = ""
    @State private var showCheckIn = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch tab {
                case .fuel:
                    FuelScreenView(store: store, referenceToday: store.selectedDate)
                case .workouts:
                    WorkoutsScreenView(store: store)
                }
            }
            V2BottomBar(tab: $tab)
        }
        .background(V2Color.bg.ignoresSafeArea())
        .onAppear {
            store.load(from: context)
            if let name = profiles.first?.name, !name.isEmpty {
                store.userName = name
            }
            maybePresentCheckIn()
        }
        .onChange(of: store.selectedDate) { _, _ in
            store.syncRailIndices()
            store.save(context: context)
        }
        .onChange(of: tab) { _, _ in
            store.save(context: context)
        }
        .overlay {
            if showCheckIn {
                Color.black.opacity(0.35).ignoresSafeArea()
            }
        }
        .sheet(isPresented: $showCheckIn) {
            CheckInSheetView(store: store)
                .presentationDetents([.height(772)])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(32)
                .interactiveDismissDisabled()
                .onDisappear {
                    markCheckInDone()
                    store.save(context: context)
                }
        }
    }

    private func maybePresentCheckIn() {
        let key = FuelDayPlan.dayKey(Date())
        if lastCheckInDay != key {
            showCheckIn = true
        }
    }

    private func markCheckInDone() {
        lastCheckInDay = FuelDayPlan.dayKey(Date())
    }
}

struct V2PaywallSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text("Plates Pro")
                .font(V2Font.serif(30))
            Text("$4.99/month")
                .font(V2Font.inter(16, .semibold))
                .foregroundStyle(V2Color.sec)
            Text("Fit my day, smarter targets, and check-in insights.")
                .font(V2Font.inter(14, .medium))
                .multilineTextAlignment(.center)
                .foregroundStyle(V2Color.sec)
            Button("Continue") { dismiss() }
                .font(V2Font.inter(16, .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(V2Color.ink)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .padding(24)
        .presentationDetents([.medium])
    }
}

struct V2DebugSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("isPro") private var isPro = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Debug") {
                    Toggle("Plates Pro (debug)", isOn: $isPro)
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
}

#Preview {
    V2RootView()
        .modelContainer(SampleData.previewContainer())
}
