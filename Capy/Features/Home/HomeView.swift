import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @Environment(CapyAppState.self) private var appState

    @Query(sort: \Feed.takenAt, order: .reverse) private var feeds: [Feed]
    @Query private var capys: [Capybara]
    @Query private var settingsList: [CapySettings]

    @State private var viewModel = HomeViewModel()
    @State private var showHistory = false
    @State private var showSettings = false
    @State private var timer: Timer?

    private var capy: Capybara? { capys.first }
    private var settings: CapySettings? { settingsList.first }

    var body: some View {
        NavigationStack {
            Group {
                if let capy, let settings {
                    let snap = viewModel.snapshot(capy: capy, settings: settings, feeds: feeds)
                    let avatar = viewModel.avatarState(capy: capy, settings: settings, feeds: feeds)
                    let rest = SharedStore.effectiveRestWeekdays(settings: settings, at: viewModel.tick)
                    let tokens = viewModel.lastSevenDayTokens(feeds: feeds, restWeekdays: rest, capy: capy)
                    let today = viewModel.homeTodayMetrics(avatar: avatar, snap: snap)
                    let model = PxModelBuilder.homeModel(
                        capy: capy,
                        snap: snap,
                        avatar: avatar,
                        caption: viewModel.caption(avatar: avatar, feeds: feeds),
                        todayFraction: today.fraction,
                        todayText: today.text,
                        dayTokens: tokens,
                        at: viewModel.tick
                    )
                    ZStack(alignment: .bottom) {
                        PxHomeView(
                            model: model,
                            onFeed: { appState.showCamera = true },
                            onHistory: { showHistory = true },
                            onSettings: { showSettings = true }
                        )
                        #if DEBUG
                        debugStatePicker
                            .padding(.horizontal, 24)
                            .padding(.bottom, 88)
                        #endif
                    }
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $showHistory) { HistoryView() }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .fullScreenCover(isPresented: Binding(
                get: { appState.showCamera },
                set: { appState.showCamera = $0 }
            )) { CameraFlowView() }
            .fullScreenCover(isPresented: Binding(
                get: { appState.showFed },
                set: { appState.showFed = $0 }
            )) {
                if let image = appState.lastFedImage, let capy, let settings = settingsList.first {
                    FedView(
                        name: capy.name,
                        image: image,
                        streakDay: appState.lastFedStreakDay,
                        newStreak: appState.lastFedWasNewStreak,
                        settings: settings
                    )
                }
            }
        }
        .onAppear { startTimer(); bootstrap() }
        .onDisappear { timer?.invalidate() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                viewModel.refreshTick()
                reconcile()
            }
        }
    }

    private func bootstrap() {
        guard let capy, let settings else { return }
        CapyReconciler.reconcile(capy: capy, settings: settings, feeds: feeds)
        let snap = viewModel.snapshot(capy: capy, settings: settings, feeds: feeds)
        Task { await CapyNotifications.reschedule(snapshot: snap, notificationsEnabled: settings.notificationsEnabled) }
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            viewModel.refreshTick()
            reconcile()
        }
    }

    private func reconcile() {
        guard let capy, let settings else { return }
        CapyReconciler.reconcile(capy: capy, settings: settings, feeds: feeds)
        try? context.save()
    }

    #if DEBUG
    private var debugStatePicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("DEBUG · capy state")
                .font(PxFont.make(12, .semibold))
                .foregroundStyle(Px.textSecondary)
            Picker("State", selection: Binding(
                get: { viewModel.debugAvatarOverride },
                set: { viewModel.debugAvatarOverride = $0 }
            )) {
                Text("Auto").tag(Optional<AvatarState>.none)
                ForEach(AvatarState.allCases, id: \.self) { state in
                    Text(state.label).tag(Optional(state))
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(12)
        .pixelBox(fill: Px.card, size: .small)
        .accessibilityIdentifier("debugAvatarStatePicker")
    }
    #endif
}

#Preview {
    HomeView()
        .environment(CapyAppState())
        .modelContainer(try! SharedStore.modelContainer())
}
