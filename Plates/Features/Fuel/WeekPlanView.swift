import SwiftUI
import SwiftData

struct WeekPlanView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Meal.name) private var meals: [Meal]

    @State private var selectedDay = Calendar.current.startOfDay(for: Date())

    private var weekDays: [Date] {
        guard let interval = Calendar.current.dateInterval(of: .weekOfYear, for: Date()) else { return [] }
        return (0..<7).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: interval.start) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(weekDays, id: \.self) { day in
                        let isSelected = Calendar.current.isDate(day, inSameDayAs: selectedDay)
                        Button {
                            selectedDay = day
                        } label: {
                            VStack(spacing: 4) {
                                Text(day.formatted(.dateTime.weekday(.narrow)))
                                    .font(PlatesFont.bodySemibold(12))
                                Text(day.formatted(.dateTime.day()))
                                    .font(PlatesFont.secondary(11))
                            }
                            .padding(10)
                            .background(isSelected ? PlatesColor.ink : PlatesColor.surface)
                            .foregroundStyle(isSelected ? PlatesColor.primaryButtonText : PlatesColor.ink)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            let plan = PlatesDataStore.dayPlan(for: selectedDay, context: context)
            let targets = PlatesDataStore.targets(for: selectedDay, context: context)
            let routine = PlatesDataStore.routine(for: selectedDay, context: context)

            PlatesCard {
                VStack(alignment: .leading, spacing: 8) {
                    if Calendar.current.isDateInToday(selectedDay) {
                        Text("TODAY")
                            .platesLabelCaps()
                            .foregroundStyle(PlatesColor.accent)
                    }
                    Text(routine?.name ?? "Rest day")
                        .font(PlatesFont.bodySemibold())
                    Text("\(targets.kcal) kcal target · \(targets.proteinG) g protein")
                        .font(PlatesFont.secondary())
                        .foregroundStyle(PlatesColor.muted)
                }
            }

            if plan.plannedMeals.isEmpty {
                PlatesCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("No meals planned")
                            .font(PlatesFont.bodyMedium())
                        Button("Auto-fill from favorites") {
                            autoFill(day: selectedDay, plan: plan, target: targets)
                        }
                        .font(PlatesFont.bodySemibold())
                    }
                }
            } else {
                ForEach(plan.plannedMeals.sorted { ($0.slotTime ?? .distantPast) < ($1.slotTime ?? .distantPast) }, id: \.id) { planned in
                    HStack {
                        Text(planned.meal?.name ?? "Meal")
                        Spacer()
                        Text("\(Int(plannedMacros(planned).kcal)) kcal")
                            .foregroundStyle(PlatesColor.muted)
                    }
                    .font(PlatesFont.bodyMedium())
                }
            }

            Menu("Add meal to this day") {
                ForEach(meals, id: \.id) { meal in
                    Button(meal.name) { addMeal(meal, to: plan) }
                }
            }
            .font(PlatesFont.bodySemibold())
        }
    }

    private func plannedMacros(_ planned: PlannedMeal) -> (kcal: Double, protein: Double) {
        guard let meal = planned.meal else { return (0, 0) }
        var k = 0.0, p = 0.0
        for ing in meal.ingredients {
            guard let f = ing.food else { continue }
            k += f.kcal * ing.servings * planned.servings
            p += f.protein * ing.servings * planned.servings
        }
        return (k, p)
    }

    private func addMeal(_ meal: Meal, to plan: DayPlan) {
        let planned = PlannedMeal(meal: meal, servings: 1, slotLabel: meal.timingTagsRaw.first ?? "Meal")
        planned.dayPlan = plan
        context.insert(planned)
        try? context.save()
    }

    private func autoFill(day: Date, plan: DayPlan, target: DailyTargetsResult) {
        let favorites = meals.filter(\.isFavorite)
        guard !favorites.isEmpty else { return }
        for (i, meal) in favorites.prefix(3).enumerated() {
            var comps = Calendar.current.dateComponents([.year, .month, .day], from: day)
            comps.hour = 8 + i * 4
            let when = Calendar.current.date(from: comps)
            let planned = PlannedMeal(meal: meal, servings: 1, slotLabel: "Meal \(i + 1)", slotTime: when)
            planned.dayPlan = plan
            context.insert(planned)
        }
        try? context.save()
    }
}

#Preview {
    WeekPlanView()
        .modelContainer(SampleData.previewContainer())
}
