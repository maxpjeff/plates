import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var context
    @Bindable var profile: UserProfile

    @State private var step = 0
    @State private var selectedGoals: Set<Goal> = []
    @State private var trainingDays = 4
    @State private var split: StarterSplit = .upperLower
    @State private var age = 30
    @State private var heightCm = 175.0
    @State private var weightKg = 79.0
    @State private var units: WeightUnit = .lb

    private let totalSteps = 6

    var body: some View {
        VStack(spacing: 0) {
            progressDots
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    stepContent
                }
                .padding(24)
            }
            footerButtons
        }
        .background(PlatesColor.bg.ignoresSafeArea())
        .onAppear {
            selectedGoals = Set(profile.goals)
            trainingDays = profile.trainingDaysPerWeek
            split = StarterSplit.recommended(for: trainingDays)
            units = profile.units
            if let w = profile.bodyWeightKg { weightKg = w }
        }
    }

    private var progressDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { i in
                Capsule()
                    .fill(i <= step ? PlatesColor.accent : PlatesColor.soft)
                    .frame(width: i == step ? 24 : 8, height: 8)
            }
        }
        .padding(.top, 16)
    }

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case 0:
            question("What are you working toward?")
            ForEach(Goal.allCases) { goal in
                optionCard(goal.label, selected: selectedGoals.contains(goal)) {
                    if selectedGoals.contains(goal) { selectedGoals.remove(goal) }
                    else { selectedGoals.insert(goal) }
                }
            }
        case 1:
            question("How long have you been lifting?")
            experienceCard("New to it", exp: .new, detail: .simple)
            experienceCard("A year or two", exp: .someYears, detail: .balanced)
            experienceCard("Several years", exp: .many, detail: .dialedIn)
        case 2:
            question("How do you like to track food?")
            detailCard("Just guide me", level: .simple)
            detailCard("Key numbers", level: .balanced)
            detailCard("Everything", level: .dialedIn)
        case 3:
            question("How many days can you train?")
            Stepper("\(trainingDays) days per week", value: $trainingDays, in: 2...6)
                .font(PlatesFont.body())
                .onChange(of: trainingDays) { _, v in split = StarterSplit.recommended(for: v) }
            Text("Starter split")
                .platesLabelCaps()
            ForEach(StarterSplit.allCases) { s in
                optionCard(s.label, selected: split == s) { split = s }
            }
        case 4:
            question("A few numbers for your targets")
            Picker("Sex", selection: $profile.sexRaw) {
                Text("Male").tag(Sex.male.rawValue)
                Text("Female").tag(Sex.female.rawValue)
                Text("Prefer not to say").tag(Sex.preferNotToSay.rawValue)
            }
            Stepper("Age: \(age)", value: $age, in: 16...80)
            Stepper("Height: \(Int(heightCm)) cm", value: $heightCm, in: 140...220, step: 1)
            Picker("Units", selection: $units) {
                Text("lb").tag(WeightUnit.lb)
                Text("kg").tag(WeightUnit.kg)
            }
            .pickerStyle(.segmented)
            Stepper(weightLabel, value: $weightKg, in: 40...200, step: 0.5)
        default:
            question("Your plan")
            summaryCard
            Text("Apple Health connects in a later update — everything works without it.")
                .font(PlatesFont.secondary())
                .foregroundStyle(PlatesColor.muted)
        }
    }

    private var weightLabel: String {
        if units == .kg {
            return String(format: "Weight: %.1f kg", weightKg)
        }
        return String(format: "Weight: %.0f lb", weightKg / 0.453592)
    }

    private var summaryCard: some View {
        let targets = previewTargets
        return PlatesCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("\(trainingDays) lifts a week · \(split.label)")
                    .font(PlatesFont.bodySemibold())
                if profile.foodDetail != .simple {
                    Text("Training days ~\(targets.kcal) kcal · rest days vary with your split.")
                        .font(PlatesFont.secondary())
                } else {
                    Text("We'll guide portions without calorie totals.")
                        .font(PlatesFont.secondary())
                }
            }
        }
    }

    private var previewTargets: DailyTargetsResult {
        let p = UserProfile(
            goals: Array(selectedGoals),
            foodDetail: profile.foodDetail,
            trainingDetail: profile.trainingDetail,
            trainingDaysPerWeek: trainingDays,
            units: units,
            bodyWeightKg: weightKg
        )
        return TargetsEngine.dailyTargets(
            profile: p,
            trendWeightKg: weightKg,
            weekPlan: [],
            date: Date()
        )
    }

    private var footerButtons: some View {
        HStack {
            if step > 0 {
                Button("Back") { step -= 1 }
                    .font(PlatesFont.bodyMedium())
            }
            Spacer()
            Button(step == totalSteps - 1 ? "Start Plates" : "Continue") {
                if step == totalSteps - 1 { finish() }
                else { step += 1 }
            }
            .font(PlatesFont.bodySemibold())
            .foregroundStyle(PlatesColor.primaryButtonText)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(PlatesColor.primaryButton)
            .clipShape(Capsule())
            .disabled(step == 0 && selectedGoals.isEmpty)
        }
        .padding(20)
    }

    private func question(_ text: String) -> some View {
        Text(text)
            .font(PlatesFont.screenTitle(34))
            .foregroundStyle(PlatesColor.ink)
    }

    private func optionCard(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(PlatesFont.bodySemibold())
                    .foregroundStyle(PlatesColor.ink)
                Spacer()
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(PlatesColor.good)
                }
            }
            .padding(16)
            .background(PlatesColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(selected ? PlatesColor.accent : PlatesColor.line, lineWidth: selected ? 2 : 1))
        }
        .buttonStyle(.plain)
    }

    private func experienceCard(_ title: String, exp: LiftExperience, detail: DetailLevel) -> some View {
        optionCard(title, selected: profile.liftExperienceRaw == exp.rawValue) {
            profile.liftExperienceRaw = exp.rawValue
            profile.trainingDetailRaw = detail.rawValue
        }
    }

    private func detailCard(_ title: String, level: DetailLevel) -> some View {
        optionCard(title, selected: profile.foodDetailRaw == level.rawValue) {
            profile.foodDetailRaw = level.rawValue
        }
    }

    private func finish() {
        profile.goalsRaw = selectedGoals.map(\.rawValue)
        profile.trainingDaysPerWeek = trainingDays
        profile.unitsRaw = units.rawValue
        profile.bodyWeightKg = weightKg
        profile.heightCm = heightCm
        profile.birthDate = Calendar.current.date(byAdding: .year, value: -age, to: Date()) ?? profile.birthDate
        profile.onboardingComplete = true

        OnboardingSplitBuilder.apply(split: split, trainingDays: trainingDays, context: context)
        context.insert(BodyWeightEntry(date: Date(), weightKg: weightKg, source: .manual))
        try? context.save()
    }
}

#Preview {
    OnboardingView(profile: UserProfile())
        .modelContainer(SampleData.previewContainer())
}
