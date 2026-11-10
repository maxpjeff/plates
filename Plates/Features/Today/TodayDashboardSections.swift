import SwiftUI
import SwiftData
import UIKit

struct TodayDashboardSections: View {
    @Environment(\.modelContext) private var context
    @Environment(\.startWorkout) private var startWorkout
    @Query private var profiles: [UserProfile]

    @State private var routineForActions: Routine?
    @State private var routineToEdit: Routine?
    @State private var showQuickFood = false

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            todayHeader
            workoutSection
            TrainingDayFuelCard(profile: profile)
            MealsAroundLiftSection(onQuickLog: { showQuickFood = true })
        }
        .sheet(item: $routineForActions) { routine in
            RoutineActionsSheet(routine: routine) {
                routineToEdit = routine
            }
        }
        .sheet(item: $routineToEdit) { routine in
            NavigationStack {
                RoutineEditorView(existing: routine)
            }
        }
        .sheet(isPresented: $showQuickFood) {
            FoodSearchView(pickMode: true) { food in
                let entry = FoodLogEntry(date: Date(), food: food, servings: 1, slot: "Quick add", source: .unplanned)
                context.insert(entry)
                let plan = PlatesDataStore.dayPlan(for: Date(), context: context)
                let planned = PlannedMeal(food: food, servings: 1, slotLabel: "Quick add", isEaten: true, eatenAt: Date())
                planned.dayPlan = plan
                context.insert(planned)
                try? context.save()
            }
        }
    }

    private var todayHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Today")
                .font(PlatesFont.statLabel())
            Text(Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                .font(PlatesFont.bodyMedium())
                .foregroundStyle(PlatesColor.muted)
        }
    }

    @ViewBuilder
    private var workoutSection: some View {
        if let routine = PlatesDataStore.routine(for: Date(), context: context) {
            WorkoutHeroCard(routine: routine, profile: profile, onManage: {
                routineForActions = routine
            }, onStart: {
                startWorkout(routine)
            })
        } else {
            PlatesCard(style: .inset) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Rest day")
                        .font(PlatesFont.bodySemibold())
                    Text("Lighter carbs, keep protein steady.")
                        .font(PlatesFont.secondary())
                        .foregroundStyle(PlatesColor.muted)
                }
            }
        }
    }
}

struct WorkoutHeroCard: View {
    let routine: Routine
    let profile: UserProfile?
    var onManage: () -> Void
    var onStart: () -> Void

    var body: some View {
        PlatesCard(style: .elevated) {
            VStack(alignment: .leading, spacing: 14) {
                Button(action: onManage) {
                    HStack(alignment: .top) {
                        TextCardSticker(label: routine.shortLabel, color: routine.stickerColor)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(routine.name)
                                .font(PlatesFont.bodySemibold(17))
                                .foregroundStyle(PlatesColor.ink)
                            Text("\(routine.items.count) exercises · \(routine.dayType.rawValue.capitalized)")
                                .font(PlatesFont.secondary())
                                .foregroundStyle(PlatesColor.muted)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(PlatesColor.muted)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Manage \(routine.name)")

                ForEach(routine.items.sorted { $0.order < $1.order }.prefix(3), id: \.id) { item in
                    if let units = profile?.units {
                        let target = ProgressionEngine.formatSetTarget(
                            weightKg: 60,
                            sets: item.sets,
                            repMin: item.repMin,
                            repMax: item.repMax,
                            units: units
                        )
                        Text("\(item.displayTitle) · \(target)")
                            .font(PlatesFont.secondary(12))
                            .foregroundStyle(PlatesColor.muted)
                    }
                }

                Button(action: onStart) {
                    Text("Start workout")
                        .font(PlatesFont.bodySemibold())
                        .foregroundStyle(PlatesColor.primaryButtonText)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(PlatesColor.primaryButton)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct TrainingDayFuelCard: View {
    @Environment(\.modelContext) private var context
    let profile: UserProfile?

    var body: some View {
        let targets = PlatesDataStore.targets(for: Date(), context: context)
        let eaten = PlatesDataStore.macroTotals(for: Date(), context: context)
        let planned = PlatesDataStore.plannedMacroTotals(for: Date(), context: context)
        let detail = profile?.foodDetail ?? .balanced
        let isRest = PlatesDataStore.routine(for: Date(), context: context) == nil

        PlatesCard {
            VStack(alignment: .leading, spacing: 14) {
                Text(isRest ? "REST DAY" : "TRAINING DAY")
                    .platesLabelCaps()
                if detail == .simple {
                    Text(simpleFuelCopy(eaten: eaten, planned: planned, targets: targets))
                        .font(PlatesFont.body())
                } else {
                    PlannedMacroBar(
                        label: "Calories",
                        planned: planned.kcal,
                        eaten: eaten.kcal,
                        target: Double(targets.kcal),
                        unit: "kcal"
                    )
                    PlannedMacroBar(
                        label: "Protein",
                        planned: planned.protein,
                        eaten: eaten.protein,
                        target: Double(targets.proteinG)
                    )
                    if detail == .dialedIn {
                        MacroBar(label: "Carbs (eaten)", current: eaten.carbs, target: Double(targets.carbsG), fill: PlatesColor.carbsMacro)
                        MacroBar(label: "Fat (eaten)", current: eaten.fat, target: Double(targets.fatG), fill: PlatesColor.fatMacro)
                    }
                }
                Text("Gold = planned · Highlight = eaten")
                    .font(PlatesFont.secondary(11))
                    .foregroundStyle(PlatesColor.muted)
            }
        }
    }

    private func simpleFuelCopy(
        eaten: (kcal: Double, protein: Double, carbs: Double, fat: Double),
        planned: (kcal: Double, protein: Double, carbs: Double, fat: Double),
        targets: DailyTargetsResult
    ) -> String {
        _ = targets
        let ratio = eaten.kcal / max(planned.kcal, 1)
        if ratio < 0.5 { return "Plenty of room in today's plan." }
        if eaten.kcal > planned.kcal * 1.1 { return "A bit over what you planned to eat." }
        return "On track with today's plan."
    }
}

struct MealsAroundLiftSection: View {
    @Environment(\.modelContext) private var context
    var onQuickLog: () -> Void

    var body: some View {
        let plan = PlatesDataStore.dayPlan(for: Date(), context: context)
        let sorted = plan.plannedMeals.sorted { ($0.slotTime ?? .distantPast) < ($1.slotTime ?? .distantPast) }

        VStack(alignment: .leading, spacing: 12) {
            Text("Meals around your lift")
                .font(PlatesFont.sectionTitle(20))

            ForEach(sorted, id: \.id) { planned in
                mealRow(planned)
            }

            Button(action: onQuickLog) {
                Label("Quick log food", systemImage: "plus")
                    .font(PlatesFont.bodySemibold())
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.plain)
            .foregroundStyle(PlatesColor.accent)
        }
    }

    private func mealRow(_ planned: PlannedMeal) -> some View {
        PlatesCard(padding: 12, style: .standard) {
            HStack(spacing: 12) {
                Button {
                    planned.isEaten.toggle()
                    planned.eatenAt = planned.isEaten ? Date() : nil
                    try? context.save()
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Image(systemName: planned.isEaten ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(planned.isEaten ? PlatesColor.good : PlatesColor.muted)
                }
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(planned.slotLabel)
                            .platesLabelCaps()
                        if let time = planned.slotTime {
                            Text(time.formatted(date: .omitted, time: .shortened))
                                .font(PlatesFont.secondary(11))
                                .foregroundStyle(PlatesColor.muted)
                        }
                    }
                    Text(planned.meal?.name ?? planned.food?.name ?? "Meal")
                        .font(PlatesFont.bodySemibold())
                    Text(mealMacrosLabel(planned))
                        .font(PlatesFont.secondary())
                        .foregroundStyle(PlatesColor.muted)
                }
                Spacer()
            }
        }
    }

    private func mealMacrosLabel(_ planned: PlannedMeal) -> String {
        let m = PlatesDataStore.mealMacros(planned)
        return "\(Int(m.kcal)) kcal · \(Int(m.protein)) g protein"
    }
}
