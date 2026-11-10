import SwiftData
import SwiftUI

struct OnboardingFlowView: View {
    @Environment(\.modelContext) private var context
    @State private var step = 0
    @State private var name = "Biscuit"
    @State private var restDays: Set<Int> = [1]
    @State private var shakeRest = false

    private let weekdaySymbols = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        ZStack {
            PixelBackground()
            VStack(spacing: 0) {
                HStack {
                    if step > 0 {
                        PixelIconButton(icon: "pixel_back", accessibilityText: "Back") {
                            withAnimation(.spring()) { step -= 1 }
                        }
                    }
                    Spacer()
                    progressDots
                    Spacer()
                    Color.clear.frame(width: 38, height: 38)
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
        .preferredColorScheme(.light)
    }

    private var progressDots: some View {
        HStack(spacing: 6) {
            ForEach(0..<5, id: \.self) { i in
                Rectangle()
                    .fill(i <= step ? Px.orange : Px.segmentEmpty)
                    .frame(width: 10, height: 10)
                    .overlay {
                        if i <= step {
                            Rectangle().stroke(Px.ink, lineWidth: 2)
                        }
                    }
            }
        }
    }

    private var meetStep: some View {
        onboardingPage(button: "Let's go", action: { step = 1 }) {
            CapySprite(status: .lockedIn, maxHeight: 220)
            Text("Meet your capybara.")
                .font(PxFont.screenTitle)
                .foregroundStyle(Px.ink)
                .multilineTextAlignment(.center)
            VStack(alignment: .leading, spacing: 16) {
                onboardingRow(icon: "pixel_camera", text: "Snap a photo when you work out")
                onboardingRow(icon: "pixel_flame", text: "One feed marks today complete—show up daily")
                onboardingRow(icon: "pixel_photos", text: "Skip too long and it gets lazy")
            }
        }
    }

    private var nameStep: some View {
        onboardingPage(
            button: "That's the one",
            disabled: name.trimmingCharacters(in: .whitespaces).isEmpty,
            action: { step = 2 }
        ) {
            Text("What's their name?")
                .font(PxFont.screenTitle)
                .foregroundStyle(Px.ink)
            TextField("Biscuit", text: $name)
                .font(PxFont.make(24, .bold))
                .foregroundStyle(Px.ink)
                .padding(14)
                .pixelBox(fill: Px.card, size: .small)
                .onChange(of: name) { _, new in
                    if new.count > 16 { name = String(new.prefix(16)) }
                }
            HStack(spacing: 10) {
                ForEach(["Biscuit", "Mochi", "Waffles"], id: \.self) { chip in
                    Button(chip) { name = chip }
                        .font(PxFont.make(18, .bold))
                        .foregroundStyle(Px.ink)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .buttonStyle(PixelButtonStyle(fill: Px.yellow, size: .small))
                }
            }
        }
    }

    private var restStep: some View {
        onboardingPage(button: "Continue", action: { step = 3 }) {
            Text("When are your rest days?")
                .font(PxFont.screenTitle)
                .foregroundStyle(Px.ink)
            Text("\(name) won't need a feed on these days. Pick up to 3.")
                .font(PxFont.body)
                .foregroundStyle(Px.textSecondary)
                .multilineTextAlignment(.center)
            weekdayRow
            if shakeRest {
                Text("Max 3 rest days")
                    .font(PxFont.caption)
                    .foregroundStyle(Px.flame)
            }
            Button("No rest days") { restDays.removeAll() }
                .font(PxFont.make(17, .semibold))
                .foregroundStyle(Px.textSecondary)
                .underline()
        }
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
            CapySprite(status: .couchMode, maxHeight: 160)
            Text("We'll warn you before \(name) gets lazy.")
                .font(PxFont.make(26, .bold))
                .foregroundStyle(Px.ink)
                .multilineTextAlignment(.center)
            Text("A nudge before 12 PM on workout days if you haven't fed yet. No spam.")
                .font(PxFont.body)
                .foregroundStyle(Px.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private var widgetStep: some View {
        onboardingPage(button: "Done", action: finishOnboarding) {
            LockScreenWidgetIllustration()
            VStack(alignment: .leading, spacing: 12) {
                Text("1. Press and hold your lock screen").font(PxFont.body)
                Text("2. Tap Customize, then the widget area").font(PxFont.body)
                Text("3. Add \(AppConstants.appName)").font(PxFont.body)
            }
            .foregroundStyle(Px.ink)
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
                PixelPrimaryButton(title: button, icon: nil, action: action)
                    .opacity(disabled ? 0.4 : 1)
                    .disabled(disabled)
                if let secondary {
                    Button(secondary.0, action: secondary.1)
                        .font(PxFont.make(17, .semibold))
                        .foregroundStyle(Px.textSecondary)
                        .underline()
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .padding(.horizontal, 24)
    }

    private func onboardingRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            PixelIcon(icon, size: 24)
            Text(text).font(PxFont.body).foregroundStyle(Px.ink)
        }
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
        Rectangle()
            .fill(Px.ink.opacity(0.85))
            .frame(height: 140)
            .overlay(alignment: .bottomTrailing) {
                Rectangle()
                    .strokeBorder(Px.orange, lineWidth: 3)
                    .frame(width: 44, height: 44)
                    .padding(16)
            }
            .overlay(Rectangle().strokeBorder(Px.ink, lineWidth: 2))
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
