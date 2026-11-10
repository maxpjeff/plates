import SwiftUI
import SwiftData

struct FuelTodayPanel: View {
    @Environment(\.modelContext) private var context
    @State private var selectedDate = Calendar.current.startOfDay(for: Date())
    @Query private var schedules: [WeekSchedule]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            WeekStripView(selectedDate: $selectedDate, dayLabels: weekLoadLabels)

            let targets = PlatesDataStore.targets(for: selectedDate, context: context)
            let eaten = PlatesDataStore.macroTotals(for: selectedDate, context: context)
            let load = HybridDataStore.dayLoad(for: selectedDate, context: context)

            PlatesCard(padding: 18, style: .elevated) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        if let load {
                            DayLoadBadge(label: load.label)
                        }
                        Text("Fuel")
                            .font(PlatesFont.bodySemibold())
                        Spacer()
                        Text("\(Int(eaten.kcal)) / \(targets.kcal) kcal")
                            .font(PlatesFont.bodySemibold())
                    }
                    Text("Base + session energy for today's label")
                        .font(PlatesFont.secondary(12))
                        .foregroundStyle(PlatesColor.muted)
                    macroLine("Protein", eaten: eaten.protein, target: Double(targets.proteinG))
                    macroLine("Carbs", eaten: eaten.carbs, target: Double(targets.carbsG))
                    macroLine("Fat", eaten: eaten.fat, target: Double(targets.fatG))

                    if let gap = PlatesDataStore.fuelGap(for: selectedDate, context: context) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Plan is \(gap.gap) kcal short")
                                .font(PlatesFont.bodySemibold())
                            Text("Add a banana to your next snack (+105 kcal)")
                                .font(PlatesFont.secondary())
                                .foregroundStyle(PlatesColor.muted)
                        }
                        .padding(.top, 4)
                    }
                }
            }

            todaysFoodList
        }
    }

    private var weekLoadLabels: [Date: DayLoadLabel] {
        guard let interval = Calendar.current.dateInterval(of: .weekOfYear, for: selectedDate) else { return [:] }
        var map: [Date: DayLoadLabel] = [:]
        for offset in 0..<7 {
            guard let day = Calendar.current.date(byAdding: .day, value: offset, to: interval.start) else { continue }
            let weekday = Calendar.current.component(.weekday, from: day)
            if let schedule = schedules.first(where: { $0.weekday == weekday }),
               let label = schedule.dayLoadLabel {
                map[Calendar.current.startOfDay(for: day)] = label
            }
        }
        return map
    }

    private func macroLine(_ title: String, eaten: Double, target: Double) -> some View {
        HStack {
            Text(title)
                .frame(width: 64, alignment: .leading)
                .foregroundStyle(PlatesColor.muted)
            Text("\(Int(eaten))/\(Int(target))")
                .font(PlatesFont.bodySemibold())
            Spacer()
            Text("\(max(0, Int(target - eaten))) left")
                .font(PlatesFont.secondary(12))
                .foregroundStyle(PlatesColor.muted)
        }
    }

    private var todaysFoodList: some View {
        let plan = PlatesDataStore.dayPlan(for: selectedDate, context: context)
        let sorted = plan.plannedMeals.sorted { ($0.slotTime ?? .distantPast) < ($1.slotTime ?? .distantPast) }
        let eatenCount = sorted.filter(\.isEaten).count

        return VStack(alignment: .leading, spacing: 10) {
            Text("Today's food · \(eatenCount) eaten · \(sorted.count - eatenCount) planned")
                .font(PlatesFont.bodySemibold())
            ForEach(sorted, id: \.id) { planned in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(planned.meal?.name ?? planned.food?.name ?? "Meal")
                            .font(PlatesFont.bodyMedium())
                        let m = PlatesDataStore.mealMacros(planned)
                        Text("P \(Int(m.protein))g · C \(Int(m.carbs))g · F \(Int(m.fat))g")
                            .font(PlatesFont.secondary(11))
                            .foregroundStyle(PlatesColor.muted)
                    }
                    Spacer()
                    Text("\(Int(PlatesDataStore.mealMacros(planned).kcal))")
                        .font(PlatesFont.bodySemibold())
                    if let t = planned.slotTime {
                        Text(t.formatted(date: .omitted, time: .shortened))
                            .font(PlatesFont.secondary(11))
                            .foregroundStyle(PlatesColor.muted)
                    }
                }
                .padding(.vertical, 6)
                Divider().overlay(PlatesColor.divider)
            }
        }
    }
}
