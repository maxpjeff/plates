import Foundation
import SwiftData

@MainActor
enum AccountabilityDataStore {
    static func monthlySummary(for reference: Date = Date(), context: ModelContext) -> MonthlyAccountabilitySummary {
        let calendar = Calendar.current
        let thisMonth = dayInputs(forMonthContaining: reference, context: context, calendar: calendar)
        let prevStart = calendar.date(byAdding: .month, value: -1, to: reference) ?? reference
        let prevMonth = dayInputs(forMonthContaining: prevStart, context: context, calendar: calendar)
        return AccountabilityEngine.monthlySummary(
            monthContaining: reference,
            inputs: thisMonth,
            previousMonthInputs: prevMonth,
            calendar: calendar
        )
    }

    private static func dayInputs(
        forMonthContaining reference: Date,
        context: ModelContext,
        calendar: Calendar
    ) -> [DayAccountabilityInput] {
        guard let interval = calendar.dateInterval(of: .month, for: reference) else { return [] }
        let sessions = (try? context.fetch(FetchDescriptor<WorkoutSession>())) ?? []
        let completedDays = Set(
            sessions
                .filter { $0.endedAt != nil }
                .map { calendar.startOfDay(for: $0.date) }
        )

        var inputs: [DayAccountabilityInput] = []
        var day = interval.start
        while day < interval.end {
            let routine = PlatesDataStore.routine(for: day, context: context)
            let targets = PlatesDataStore.targets(for: day, context: context)
            let eaten = PlatesDataStore.macroTotals(for: day, context: context)
            let planned = PlatesDataStore.plannedMacroTotals(for: day, context: context)
            let proteinTarget = max(Double(targets.proteinG), 1)
            let proteinRatio = eaten.protein / proteinTarget
            let fuelDenominator = max(planned.kcal, Double(targets.kcal), 1)
            let fuelRatio = eaten.kcal / fuelDenominator

            inputs.append(
                DayAccountabilityInput(
                    date: day,
                    isTrainingDay: routine != nil,
                    workoutCompleted: completedDays.contains(calendar.startOfDay(for: day)),
                    proteinRatio: proteinRatio,
                    fuelAdherenceRatio: fuelRatio
                )
            )
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return inputs
    }
}
