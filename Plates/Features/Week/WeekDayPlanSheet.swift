import SwiftUI
import SwiftData

struct WeekDayPlanSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let date: Date

    @Query(sort: \Routine.sortOrder) private var routines: [Routine]
    @Query(sort: \Meal.name) private var meals: [Meal]

    @State private var selectedRoutineID: UUID?
    @State private var workoutTime: Date = Date()
    @State private var isRestDay = false
    @State private var showAddMeal = false

    private var weekday: Int { Calendar.current.component(.weekday, from: date) }
    private var plan: DayPlan { PlatesDataStore.dayPlan(for: date, context: context) }

    private var sortedMeals: [PlannedMeal] {
        plan.plannedMeals.sorted { ($0.slotTime ?? .distantPast) < ($1.slotTime ?? .distantPast) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerSummary
                    if !isRestDay, selectedRoutineID != nil {
                        dayTimeline
                    }
                    workoutSection
                    mealsSection
                }
                .padding(20)
            }
            .background(PlatesColor.bg)
            .navigationTitle(date.formatted(.dateTime.weekday(.wide)))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        saveSchedule()
                        dismiss()
                    }
                }
            }
            .onAppear(perform: loadFromSchedule)
            .confirmationDialog("Add meal", isPresented: $showAddMeal, titleVisibility: .visible) {
                ForEach(meals, id: \.id) { meal in
                    Button(meal.name) { addMeal(meal) }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private var headerSummary: some View {
        PlatesCard {
            VStack(alignment: .leading, spacing: 6) {
                Text(date.formatted(.dateTime.month(.wide).day().year()))
                    .font(PlatesFont.secondary())
                    .foregroundStyle(PlatesColor.muted)
                let targets = PlatesDataStore.targets(for: date, context: context)
                Text("\(targets.kcal) kcal · \(targets.proteinG) g protein")
                    .font(PlatesFont.bodySemibold())
            }
        }
    }

    private var dayTimeline: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Day timeline")
                .font(PlatesFont.bodySemibold(17))
            PlatesCard(padding: 12) {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(timelineEntries, id: \.id) { entry in
                        HStack(spacing: 10) {
                            Text(entry.time.formatted(date: .omitted, time: .shortened))
                                .font(PlatesFont.bodySemibold(13))
                                .frame(width: 64, alignment: .leading)
                            Image(systemName: entry.icon)
                                .foregroundStyle(PlatesColor.accent)
                            Text(entry.title)
                                .font(PlatesFont.bodyMedium())
                            Spacer()
                        }
                    }
                }
            }
        }
    }

    private struct TimelineEntry: Identifiable {
        let id = UUID()
        let time: Date
        let title: String
        let icon: String
    }

    private var timelineEntries: [TimelineEntry] {
        var entries: [TimelineEntry] = []
        if !isRestDay, selectedRoutineID != nil {
            entries.append(
                TimelineEntry(
                    time: workoutTime,
                    title: selectedRoutineName,
                    icon: "figure.strengthtraining.traditional"
                )
            )
        }
        for meal in sortedMeals {
            entries.append(
                TimelineEntry(
                    time: meal.slotTime ?? defaultTime(hour: 12),
                    title: meal.meal?.name ?? meal.slotLabel,
                    icon: "fork.knife"
                )
            )
        }
        return entries.sorted { $0.time < $1.time }
    }

    private var workoutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Workout")
                .font(PlatesFont.bodySemibold(17))
            PlatesCard {
                VStack(alignment: .leading, spacing: 14) {
                    Toggle("Rest day", isOn: $isRestDay)
                        .font(PlatesFont.bodyMedium())
                    if !isRestDay {
                        Menu {
                            Button("No routine") { selectedRoutineID = nil }
                            ForEach(routines, id: \.id) { routine in
                                Button(routine.name) { selectedRoutineID = routine.id }
                            }
                        } label: {
                            HStack {
                                Text("Routine")
                                    .foregroundStyle(PlatesColor.muted)
                                Spacer()
                                Text(selectedRoutineName)
                                    .font(PlatesFont.bodySemibold())
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.caption)
                                    .foregroundStyle(PlatesColor.muted)
                            }
                        }
                        DatePicker("Lift time", selection: $workoutTime, displayedComponents: .hourAndMinute)
                            .font(PlatesFont.bodyMedium())
                    }
                }
            }
        }
    }

    private var selectedRoutineName: String {
        guard let id = selectedRoutineID,
              let routine = routines.first(where: { $0.id == id }) else {
            return "Choose routine"
        }
        return routine.name
    }

    private var mealsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Meals")
                    .font(PlatesFont.bodySemibold(17))
                Spacer()
                Button("Add meal") { showAddMeal = true }
                    .font(PlatesFont.bodySemibold(13))
            }
            if sortedMeals.isEmpty {
                PlatesCard {
                    Text("No meals planned yet. Add meals and set times so fuel lines up with your lift.")
                        .font(PlatesFont.secondary())
                        .foregroundStyle(PlatesColor.muted)
                }
            } else {
                ForEach(sortedMeals, id: \.id) { planned in
                    mealPlanRow(planned)
                }
            }
        }
    }

    private func mealPlanRow(_ planned: PlannedMeal) -> some View {
        PlatesCard(padding: 12) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(planned.meal?.name ?? planned.slotLabel)
                        .font(PlatesFont.bodySemibold())
                    Spacer()
                    Button(role: .destructive) {
                        context.delete(planned)
                        try? context.save()
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                    }
                }
                DatePicker(
                    "Time",
                    selection: bindingMealTime(planned),
                    displayedComponents: .hourAndMinute
                )
                .font(PlatesFont.bodyMedium())
            }
        }
    }

    private func bindingMealTime(_ planned: PlannedMeal) -> Binding<Date> {
        Binding(
            get: {
                planned.slotTime ?? defaultTime(hour: 12)
            },
            set: { newValue in
                planned.slotTime = mergedTime(newValue, on: date)
                try? context.save()
            }
        )
    }

    private func loadFromSchedule() {
        if let schedule = WeekScheduleService.schedule(for: weekday, context: context) {
            isRestDay = schedule.isRest
            selectedRoutineID = schedule.routine?.id
            if let t = schedule.preferredWorkoutTime {
                workoutTime = mergedTime(t, on: date)
            } else {
                workoutTime = defaultTime(hour: 7)
            }
        } else {
            isRestDay = PlatesDataStore.routine(for: date, context: context) == nil
            selectedRoutineID = PlatesDataStore.routine(for: date, context: context)?.id
            workoutTime = defaultTime(hour: 7)
        }
    }

    private func saveSchedule() {
        let routine = routines.first { $0.id == selectedRoutineID }
        if isRestDay {
            WeekScheduleService.markRest(weekday: weekday, context: context)
        } else {
            WeekScheduleService.assign(
                routine: routine,
                to: weekday,
                workoutTime: mergedTime(workoutTime, on: date),
                context: context
            )
        }
        try? context.save()
    }

    private func addMeal(_ meal: Meal) {
        let planned = PlannedMeal(
            meal: meal,
            servings: 1,
            slotLabel: meal.timingTagsRaw.first ?? "Meal",
            slotTime: defaultTime(hour: 12)
        )
        planned.dayPlan = plan
        context.insert(planned)
        try? context.save()
    }

    private func defaultTime(hour: Int, minute: Int = 0) -> Date {
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: date)
        comps.hour = hour
        comps.minute = minute
        return Calendar.current.date(from: comps) ?? date
    }

    private func mergedTime(_ time: Date, on day: Date) -> Date {
        let t = Calendar.current.dateComponents([.hour, .minute], from: time)
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: day)
        comps.hour = t.hour
        comps.minute = t.minute
        return Calendar.current.date(from: comps) ?? day
    }
}
