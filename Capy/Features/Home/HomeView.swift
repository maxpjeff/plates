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
            ZStack {
                PaperBackground()
                if let capy, let settings {
                    homeContent(capy: capy, settings: settings)
                }
            }
            .capyPaperText()
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
                if let image = appState.lastFedImage, let capy {
                    FedView(
                        name: capy.name,
                        image: image,
                        streakDay: appState.lastFedStreakDay,
                        newStreak: appState.lastFedWasNewStreak
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
        if capy.totalFeeds == 0, !UserDefaults.standard.bool(forKey: "capy.tip.dismissed") {
            appState.showFirstFeedTip = true
        }
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

    @ViewBuilder
    private func homeContent(capy: Capybara, settings: CapySettings) -> some View {
        let snap = viewModel.snapshot(capy: capy, settings: settings, feeds: feeds)
        let avatar = viewModel.avatarState(capy: capy, settings: settings, feeds: feeds)
        let rest = SharedStore.effectiveRestWeekdays(settings: settings, at: viewModel.tick)
        let fraction = snap.todayBarFraction
        let dayTokens = viewModel.lastSevenDayTokens(feeds: feeds, restWeekdays: rest, capy: capy)

        VStack(spacing: 18) {
            header(name: capy.name, streak: snap.streak)
            if appState.showFirstFeedTip { tipBanner() }

            HeroCard(
                avatarState: avatar,
                caption: viewModel.caption(avatar: avatar, feeds: feeds)
            )
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: avatar)

            todayBlock(avatar: avatar, snap: snap, fraction: fraction)
            weekRow(tokens: dayTokens)
            Spacer(minLength: 0)

            #if DEBUG
            Picker("Debug avatar", selection: Binding(
                get: { viewModel.debugAvatarOverride },
                set: { viewModel.debugAvatarOverride = $0 }
            )) {
                Text("Auto").tag(Optional<AvatarState>.none)
                ForEach(AvatarState.allCases, id: \.self) { s in
                    Text(s.label).tag(Optional(s))
                }
            }
            .pickerStyle(.segmented)
            #endif

            CapyPrimaryButton(
                title: avatar.feedButtonTitle(name: capy.name),
                icon: "camera.fill"
            ) {
                appState.showCamera = true
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }

    private func header(name: String, streak: Int) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(dateLine)
                    .font(CapyFont.nunito(14, .heavy))
                    .kerning(0.5)
                    .textCase(.uppercase)
                    .foregroundStyle(Color(capyHex: "7A6248"))
                Text(name)
                    .font(CapyFont.fredoka(34))
                    .foregroundStyle(Theme.Color.ink)
            }
            Spacer()
            HStack(spacing: 10) {
                streakPill(streak)
                Button { showHistory = true } label: { roundNavButton(icon: "calendar") }
                Button { showSettings = true } label: { roundNavButton(icon: "gearshape.fill") }
            }
        }
        .padding(.top, 8)
    }

    private func streakPill(_ streak: Int) -> some View {
        HStack(spacing: 6) {
            CapySymbol(systemName: "flame.fill", size: 14, color: Theme.Color.flame)
            Text("\(streak)")
                .font(CapyFont.nunito(14, .heavy))
        }
        .foregroundStyle(Theme.Color.ink)
        .padding(.horizontal, 14)
        .frame(height: 44)
        .background {
            HardShadowFill(shape: Capsule(), fill: Color(capyHex: "FFD08A"), shadowY: 3, lineWidth: 2.5)
        }
    }

    private func roundNavButton(icon: String) -> some View {
        ZStack {
            Circle().fill(Theme.Color.ink).offset(y: 3)
            Circle()
                .fill(Theme.Color.card)
                .overlay(Circle().strokeBorder(Theme.Color.ink, lineWidth: 2.5))
            CapySymbol(systemName: icon, size: 18)
        }
        .frame(width: 44, height: 44)
    }

    private func todayBlock(avatar: AvatarState, snap: CapySnapshot, fraction: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Today")
                    .font(CapyFont.nunito(15, .heavy))
                    .foregroundStyle(Theme.Color.ink)
                Spacer()
                Text(snap.todayBarLabel)
                    .font(CapyFont.nunito(15, .heavy))
                    .foregroundStyle(avatar.todayBarTextColor)
            }
            HomeEnergyBar(
                fraction: fraction,
                fillColor: avatar.todayBarFillColor
            )
        }
    }

    private func weekRow(tokens: [HomeDayToken]) -> some View {
        VStack(spacing: 8) {
            HStack {
                ForEach(tokens) { token in
                    DayToken(label: token.weekdayLetter, style: mapStyle(token.style))
                        .frame(maxWidth: .infinity)
                }
            }
            Text("Grey ring = your rest day. Rest days don't break your streak.")
                .font(CapyFont.nunito(13, .heavy))
                .foregroundStyle(Theme.Color.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private func tipBanner() -> some View {
        HStack {
            Text("Take your first photo to start a streak.")
                .font(CapyFont.nunito(14, .heavy))
            Spacer()
            Button {
                UserDefaults.standard.set(true, forKey: "capy.tip.dismissed")
                appState.showFirstFeedTip = false
            } label: {
                Image(systemName: "xmark")
            }
        }
        .foregroundStyle(Theme.Color.ink)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 16).fill(Theme.Color.yellowSoft))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Theme.Color.ink, lineWidth: 2))
    }

    private func mapStyle(_ s: DayTokenStyle) -> DayToken.Style {
        switch s {
        case .fed: .fed
        case .rest: .rest
        case .missed: .missed
        case .today: .today
        case .asleep: .asleep
        case .scheduledRest: .scheduledRest
        }
    }

    private var dateLine: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        return f.string(from: viewModel.tick)
    }
}

private struct HomeEnergyBar: View {
    var fraction: CGFloat
    var fillColor: Color

    var body: some View {
        GeometryReader { geo in
            let w = max(0, min(geo.size.width, geo.size.width * fraction))
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Theme.Color.card)
                    .overlay(Capsule().strokeBorder(Theme.Color.ink, lineWidth: 2.5))
                    .background(Capsule().fill(Theme.Color.ink).offset(y: 3))
                Capsule()
                    .fill(fillColor)
                    .frame(width: w)
                    .padding(3)
                    .overlay(stripes.mask(Capsule().frame(width: max(0, w - 6)).padding(.leading, 3)))
                    .animation(.spring(response: 0.45), value: fraction)
            }
        }
        .frame(height: 22)
    }

    private var stripes: some View {
        GeometryReader { geo in
            Path { path in
                let period: CGFloat = 14
                var x: CGFloat = -period
                while x < geo.size.width + period {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x + period / 2, y: geo.size.height))
                    x += period / 2
                }
            }
            .stroke(Color.white.opacity(0.28), lineWidth: 2)
        }
    }
}

#Preview {
    HomeView()
        .environment(CapyAppState())
        .modelContainer(try! SharedStore.modelContainer())
}
