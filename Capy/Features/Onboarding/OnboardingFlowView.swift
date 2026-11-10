import SwiftData
import SwiftUI

struct OnboardingFlowView: View {
    @Environment(\.modelContext) private var context
    @State private var step = 0
    @State private var name = "Biscuit"
    @State private var restDays: Set<Int> = [1]
    @State private var shakeRest = false

    var body: some View {
        ZStack {
            PaperBackground()
                .capyPaperText()
            VStack(spacing: 0) {
                HStack {
                    if step > 0 {
                        Button {
                            withAnimation(.spring()) { step -= 1 }
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(Theme.Color.ink)
                                .frame(width: 44, height: 44)
                        }
                    }
                    Spacer()
                    OnboardingDots(step: step, total: 5)
                    Spacer()
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                TabView(selection: $step) {
                    meetStep.tag(0)
                    nameStep.tag(1)
                    restStep.tag(2)
                    remindersStep.tag(3)
                    widgetStep.tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(), value: step)
            }
        }
    }

    private var meetStep: some View {
        onboardingPage(
            button: "Let's go",
            action: { step = 1 }
        ) {
            MascotView(state: .lockedIn, size: 160)
            Text("Meet your capybara.")
                .font(CapyFont.fredoka(30))
                .foregroundStyle(Theme.Color.ink)
                .multilineTextAlignment(.center)
            VStack(alignment: .leading, spacing: 16) {
                onboardingRow(icon: "camera.fill", text: "Snap a photo when you're active")
                onboardingRow(icon: "bolt.fill", text: "That feeds your capybara for 48 hours")
                onboardingRow(icon: "sofa.fill", text: "Skip too long and it ends up on the couch")
            }
            .padding(.horizontal, 8)
        }
    }

    private var nameStep: some View {
        onboardingPage(
            button: "That's the one",
            disabled: name.trimmingCharacters(in: .whitespaces).isEmpty,
            action: { step = 2 }
        ) {
            Text("What's their name?")
                .font(CapyFont.fredoka(30))
            TextField("Biscuit", text: $name)
                .capyTextFieldChrome()
                .onChange(of: name) { _, new in
                    if new.count > 16 { name = String(new.prefix(16)) }
                }
            HStack(spacing: 10) {
                ForEach(["Biscuit", "Mochi", "Waffles"], id: \.self) { chip in
                    Button(chip) { name = chip }
                        .font(CapyFont.nunito(14, .heavy))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(Theme.Color.yellowSoft))
                        .overlay(Capsule().strokeBorder(Theme.Color.ink, lineWidth: 2))
                }
            }
        }
    }

    private var restStep: some View {
        onboardingPage(button: "Continue", action: { step = 3 }) {
            Text("When are your rest days?")
                .font(CapyFont.fredoka(30))
            Text("\(name) won't lose energy on these days. Pick up to 3.")
                .font(CapyFont.nunito(16))
                .foregroundStyle(Theme.Color.textSecondary)
                .multilineTextAlignment(.center)
            weekdayRow
            if shakeRest {
                Text("Max 3 rest days")
                    .font(CapyFont.nunito(13, .heavy))
                    .foregroundStyle(Theme.Color.flame)
            }
            Button("No rest days") {
                restDays.removeAll()
            }
            .font(CapyFont.nunito(14, .heavy))
            .foregroundStyle(Theme.Color.textSecondary)
        }
    }

    private var weekdayRow: some View {
        let symbols = ["S", "M", "T", "W", "T", "F", "S"]
        return HStack(spacing: 8) {
            ForEach(1...7, id: \.self) { wd in
                let selected = restDays.contains(wd)
                Button {
                    toggleRest(wd)
                } label: {
                    Text(symbols[wd - 1])
                        .font(CapyFont.nunito(14, .heavy))
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(selected ? Theme.Color.orangeSoft : Theme.Color.card))
                        .overlay(Circle().strokeBorder(Theme.Color.ink, lineWidth: 2))
                }
                .buttonStyle(.plain)
            }
        }
        .modifier(ShakeEffect(animating: shakeRest))
    }

    private var remindersStep: some View {
        onboardingPage(
            button: "Turn on reminders",
            action: {
                Task {
                    _ = await CapyNotifications.requestAuthorization()
                    step = 4
                }
            },
            secondary: ("Not now", { step = 4 })
        ) {
            MascotView(state: .couch, size: 120)
            Text("We'll warn you before \(name) gets lazy.")
                .font(CapyFont.fredoka(26))
                .multilineTextAlignment(.center)
            Text("One heads-up when there's 24 hours of energy left. No spam.")
                .font(CapyFont.nunito(16))
                .foregroundStyle(Theme.Color.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private var widgetStep: some View {
        onboardingPage(button: "Done", action: finishOnboarding) {
            LockScreenWidgetIllustration()
            VStack(alignment: .leading, spacing: 12) {
                Text("1. Press and hold your lock screen").font(CapyFont.nunito(16))
                Text("2. Tap Customize, then the widget area").font(CapyFont.nunito(16))
                Text("3. Add \(AppConstants.appName)").font(CapyFont.nunito(16))
            }
            .foregroundStyle(Theme.Color.ink)
        }
    }

  @ViewBuilder
    private func onboardingPage(
        button: String,
        disabled: Bool = false,
        action: @escaping () -> Void,
        secondary: (String, () -> Void)? = nil,
        @ViewBuilder content: () -> some View
    ) -> some View {
        VStack(spacing: 24) {
            Spacer(minLength: 0)
            content()
            Spacer(minLength: 0)
            VStack(spacing: 12) {
                CapyPrimaryButton(title: button, action: action)
                    .opacity(disabled ? 0.4 : 1)
                    .disabled(disabled)
                if let secondary {
                    Button(secondary.0, action: secondary.1)
                        .font(CapyFont.nunito(14, .heavy))
                        .foregroundStyle(Theme.Color.textSecondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .padding(.horizontal, 24)
    }

    private func onboardingRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            CapySymbol(systemName: icon, size: 20)
            Text(text).font(CapyFont.nunito(16))
        }
        .foregroundStyle(Theme.Color.ink)
    }

    private func toggleRest(_ wd: Int) {
        if restDays.contains(wd) {
            restDays.remove(wd)
        } else if restDays.count < 3 {
            restDays.insert(wd)
        } else {
            withAnimation(.default) { shakeRest = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { shakeRest = false }
        }
    }

    private func finishOnboarding() {
        do {
            let (capy, settings) = try SharedStore.fetchOrCreate(in: context)
            capy.name = name.trimmingCharacters(in: .whitespaces)
            settings.restWeekdays = Array(restDays).sorted()
            settings.pendingRestWeekdays = nil
            settings.pendingRestEffectiveDate = nil
            settings.hasCompletedOnboarding = true
            settings.notificationsEnabled = true
            try context.save()
            WidgetReloader.reloadAll(context: context)
        } catch {}
    }
}

private struct LockScreenWidgetIllustration: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(Theme.Color.ink.opacity(0.85))
            .frame(height: 140)
            .overlay(alignment: .bottomTrailing) {
                Circle()
                    .strokeBorder(Theme.Color.orange, lineWidth: 3)
                    .frame(width: 44, height: 44)
                    .padding(16)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .strokeBorder(Theme.Color.ink, lineWidth: 2)
            )
            .accessibilityHidden(true)
    }
}

private struct ShakeEffect: GeometryEffect {
    var animating: Bool
    var amount: CGFloat = 8
    var shakes: CGFloat = 3

    var animatableData: CGFloat {
        get { animating ? 1 : 0 }
        set {}
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        let translation = amount * sin(animatableData * .pi * shakes)
        return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
    }
}

#Preview {
    OnboardingFlowView()
        .modelContainer(try! SharedStore.modelContainer())
}
