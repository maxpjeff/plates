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
                PixelBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Settings")
                            .font(PxFont.screenTitle)
                            .foregroundStyle(Px.ink)
                            .padding(.top, 8)

                        settingsCard(title: "Capybara") {
                            Text("Name")
                                .font(PxFont.caption)
                                .foregroundStyle(Px.textSecondary)
                            TextField("Biscuit", text: $name)
                                .font(PxFont.body)
                                .foregroundStyle(Px.ink)
                                .padding(14)
                                .pixelBox(fill: Px.card, size: .small)
                                .onChange(of: name) { _, v in
                                    if v.count > 16 { name = String(v.prefix(16)) }
                                    capys.first?.name = name.trimmingCharacters(in: .whitespaces)
                                    try? context.save()
                                    WidgetReloader.reloadAll(context: context)
                                }
                        }

                        settingsCard(title: "Rest days") {
                            weekdayRow
                            if shakeRest {
                                Text("Max 3 rest days")
                                    .font(PxFont.caption)
                                    .foregroundStyle(Px.flame)
                            }
                            Text("Changes start tomorrow.")
                                .font(PxFont.caption)
                                .foregroundStyle(Px.textSecondary)
                        }

                        if let settings = settingsList.first {
                            settingsCard(title: "Reminders") {
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
                                        Text("Heads-up before lazy mode")
                                            .font(PxFont.label)
                                            .foregroundStyle(Px.ink)
                                        Text("A nudge before 12 PM on workout days if you haven't fed.")
                                            .font(PxFont.caption)
                                            .foregroundStyle(Px.textSecondary)
                                    }
                                }
                                .tint(Px.orange)
                            }
                        }

                        Button("Start over") { showResetConfirm = true }
                            .font(PxFont.make(20, .bold))
                            .foregroundStyle(Px.pinkText)
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .buttonStyle(PixelButtonStyle(fill: Px.pinkSoft, size: .small))
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .font(PxFont.make(18, .bold))
                        .foregroundStyle(Px.ink)
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
        .preferredColorScheme(.light)
    }

    private func settingsCard(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(PxFont.section)
                .foregroundStyle(Px.ink)
            content()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .pixelBox(fill: Px.card, size: .large)
    }

    private var weekdayRow: some View {
        HStack(spacing: 8) {
            ForEach(1...7, id: \.self) { wd in
                let selected = restDays.contains(wd)
                Button(weekdaySymbols[wd - 1]) { toggleRest(wd) }
                    .font(PxFont.make(18, .bold))
                    .foregroundStyle(Px.ink)
                    .frame(width: 40, height: 40)
                    .buttonStyle(PixelButtonStyle(fill: selected ? Px.orange : Px.card, size: .small))
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
