import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var capys: [Capybara]
    @Query private var settingsList: [CapySettings]
    @Query private var feeds: [Feed]

    @State private var name = ""
    @State private var restDays: Set<Int> = []
    @State private var shakeRest = false
    @State private var showResetConfirm = false

    private let weekdaySymbols = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        NavigationStack {
            ZStack {
                PaperBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Settings")
                            .font(CapyFont.fredoka(34))
                            .foregroundStyle(Theme.Color.ink)
                            .padding(.top, 8)

                        SettingsSectionCard(title: "Capybara", icon: "pawprint.fill") {
                            Text("Name")
                                .font(CapyFont.nunito(13, .heavy))
                                .foregroundStyle(Theme.Color.textSecondary)
                            TextField("Biscuit", text: $name)
                                .capyTextFieldChrome()
                                .onChange(of: name) { _, v in
                                    if v.count > 16 { name = String(v.prefix(16)) }
                                    capys.first?.name = name.trimmingCharacters(in: .whitespaces)
                                    try? context.save()
                                    WidgetReloader.reloadAll(context: context)
                                }
                        }

                        SettingsSectionCard(title: "Rest days", icon: "leaf.fill") {
                            weekdayRow
                            if shakeRest {
                                Text("Max 3 rest days")
                                    .font(CapyFont.nunito(13, .heavy))
                                    .foregroundStyle(Theme.Color.flame)
                            }
                            Text("Changes start tomorrow.")
                                .font(CapyFont.nunito(13, .heavy))
                                .foregroundStyle(Theme.Color.textSecondary)
                        }

                        if let settings = settingsList.first {
                            SettingsSectionCard(title: "Reminders", icon: "bell.fill") {
                                Toggle(isOn: Binding(
                                    get: { settings.notificationsEnabled },
                                    set: { new in
                                        settings.notificationsEnabled = new
                                        try? context.save()
                                        if let capy = capys.first {
                                            let snap = SharedStore.snapshot(
                                                capy: capy,
                                                settings: settings,
                                                feeds: feeds
                                            )
                                            Task {
                                                await CapyNotifications.reschedule(
                                                    snapshot: snap,
                                                    notificationsEnabled: new
                                                )
                                            }
                                        }
                                    }
                                )) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Heads-up before couch mode")
                                            .font(CapyFont.nunito(16, .heavy))
                                            .foregroundStyle(Theme.Color.ink)
                                        Text("One nudge when energy hits 24 hours.")
                                            .font(CapyFont.nunito(13, .heavy))
                                            .foregroundStyle(Theme.Color.textSecondary)
                                    }
                                }
                                .tint(Theme.Color.orange)
                            }
                        }

                        Button(role: .destructive) { showResetConfirm = true } label: {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 18, weight: .semibold))
                                Text("Start over")
                                    .font(CapyFont.fredoka(20))
                                Spacer()
                            }
                            .foregroundStyle(Color(capyHex: "7A1F2B"))
                            .padding(16)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(Color(capyHex: "F8D5D9"))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .strokeBorder(Theme.Color.ink, lineWidth: 2.5)
                                    )
                                    .background(
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .fill(Theme.Color.ink)
                                            .offset(y: 4)
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .font(CapyFont.fredoka(18))
                        .foregroundStyle(Theme.Color.ink)
                }
            }
            .onAppear { load() }
            .alert("Start over?", isPresented: $showResetConfirm) {
                Button("Delete everything", role: .destructive) { resetAll() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This deletes all feeds and returns to onboarding.")
            }
        }
    }

    private var weekdayRow: some View {
        HStack(spacing: 8) {
            ForEach(1...7, id: \.self) { wd in
                let selected = restDays.contains(wd)
                Button {
                    toggleRest(wd)
                } label: {
                    Text(weekdaySymbols[wd - 1])
                        .font(CapyFont.nunito(14, .heavy))
                        .foregroundStyle(Theme.Color.ink)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(selected ? Theme.Color.orangeSoft : Theme.Color.card))
                        .overlay(
                            Circle().strokeBorder(Theme.Color.ink, lineWidth: 2)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
        .modifier(ShakeEffect(animating: shakeRest))
    }

    private func load() {
        name = capys.first?.name ?? ""
        restDays = Set(settingsList.first?.restWeekdays ?? [1])
    }

    private func toggleRest(_ wd: Int) {
        guard let settings = settingsList.first else { return }
        var working = restDays
        if working.contains(wd) {
            working.remove(wd)
            shakeRest = false
        } else if working.count < 3 {
            working.insert(wd)
            shakeRest = false
        } else {
            withAnimation { shakeRest = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { shakeRest = false }
            return
        }
        restDays = working
        settings.pendingRestWeekdays = Array(working).sorted()
        let tomorrow = Calendar.current.date(
            byAdding: .day,
            value: 1,
            to: Calendar.current.startOfDay(for: Date())
        )!
        settings.pendingRestEffectiveDate = tomorrow
        try? context.save()
        WidgetReloader.reloadAll(context: context)
        if let capy = capys.first {
            let snap = SharedStore.snapshot(capy: capy, settings: settings, feeds: feeds)
            Task { await CapyNotifications.reschedule(snapshot: snap, notificationsEnabled: settings.notificationsEnabled) }
        }
    }

    private func resetAll() {
        for feed in feeds {
            PhotoStore.delete(filename: feed.photoFilename)
            context.delete(feed)
        }
        for capy in capys { context.delete(capy) }
        for s in settingsList { context.delete(s) }
        try? context.save()
        #if DEBUG
        DebugClock.shared.reset()
        #endif
        WidgetReloader.clearAndReload()
        dismiss()
    }
}

private struct SettingsSectionCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 22, style: .continuous)
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Theme.Color.yellowSoft)
                        .frame(width: 36, height: 36)
                        .overlay(Circle().strokeBorder(Theme.Color.ink, lineWidth: 2))
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.Color.ink)
                }
                Text(title)
                    .font(CapyFont.fredoka(22))
                    .foregroundStyle(Theme.Color.ink)
            }
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(shape.fill(Theme.Color.card))
        .overlay(shape.strokeBorder(Theme.Color.ink, lineWidth: 2.5))
        .background(shape.fill(Theme.Color.ink).offset(y: 5))
    }
}

private struct ShakeEffect: GeometryEffect {
    var animating: Bool
    var amount: CGFloat = 8

    var animatableData: CGFloat {
        get { animating ? 1 : 0 }
        set {}
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        let translation = amount * sin(animatableData * .pi * 3)
        return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
    }
}

#Preview {
    SettingsView()
        .modelContainer(try! SharedStore.modelContainer())
}
