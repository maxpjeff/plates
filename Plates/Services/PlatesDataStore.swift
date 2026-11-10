import Foundation
import SwiftData

@MainActor
enum PlatesDataStore {
    static func profile(context: ModelContext) -> UserProfile {
        if let existing = try? context.fetch(FetchDescriptor<UserProfile>()).first {
            return existing
        }
        let profile = UserProfile(
            name: "You",
            goals: [.buildMuscle, .feelHealthier],
            trainingDaysPerWeek: 4,
            onboardingComplete: true
        )
        context.insert(profile)
        return profile
    }

    static func trendWeightKg(context: ModelContext, fallbackKg: Double = 79) -> Double {
        let entries = (try? context.fetch(FetchDescriptor<BodyWeightEntry>())) ?? []
        let pairs = entries.map { ($0.date, $0.weightKg) }
        return TrendEngine.trendToday(entries: pairs) ?? fallbackKg
    }

    static func weekPlan(context: ModelContext) -> [WeekDayTargetInput] {
        let schedules = (try? context.fetch(FetchDescriptor<WeekSchedule>())) ?? []
        return schedules.compactMap { schedule in
            guard !schedule.isRest, let routine = schedule.routine else { return nil }
            return WeekDayTargetInput(weekday: schedule.weekday, dayType: routine.dayType)
        }
    }

    static func targets(for date: Date, context: ModelContext) -> DailyTargetsResult {
        let profile = profile(context: context)
        let weight = trendWeightKg(context: context, fallbackKg: profile.resolvedBodyWeightKg)
        let base = TargetsEngine.dailyTargets(
            profile: profile,
            trendWeightKg: weight,
            weekPlan: weekPlan(context: context),
            date: date
        )
        let load = HybridDataStore.dayLoad(for: date, context: context, planned: true)
        return FuelTargetsEngine.adjust(base: base, load: load, profile: profile)
    }

    static func fuelBreakdown(for date: Date, context: ModelContext) -> (baseKcal: Int, sessionBonus: Int, totalKcal: Int) {
        let profile = profile(context: context)
        let weight = trendWeightKg(context: context, fallbackKg: profile.resolvedBodyWeightKg)
        let base = TargetsEngine.dailyTargets(
            profile: profile,
            trendWeightKg: weight,
            weekPlan: weekPlan(context: context),
            date: date
        )
        let total = targets(for: date, context: context)
        let bonus = max(0, total.kcal - base.kcal)
        return (base.kcal, bonus, total.kcal)
    }

    static func fuelGap(for date: Date, context: ModelContext) -> (plannedKcal: Int, targetKcal: Int, gap: Int)? {
        let targets = targets(for: date, context: context)
        let planned = plannedMacroTotals(for: date, context: context)
        let gap = targets.kcal - Int(planned.kcal.rounded())
        guard gap > 15 else { return nil }
        return (Int(planned.kcal.rounded()), targets.kcal, gap)
    }

    static func dayPlan(for date: Date, context: ModelContext) -> DayPlan {
        let start = Calendar.current.startOfDay(for: date)
        let descriptor = FetchDescriptor<DayPlan>()
        if let plans = try? context.fetch(descriptor),
           let match = plans.first(where: { Calendar.current.isDate($0.date, inSameDayAs: start) }) {
            return match
        }
        let plan = DayPlan(date: start)
        context.insert(plan)
        return plan
    }

    static func routine(for date: Date, context: ModelContext) -> Routine? {
        let weekday = Calendar.current.component(.weekday, from: date)
        let schedules = (try? context.fetch(FetchDescriptor<WeekSchedule>())) ?? []
        if let scheduled = schedules.first(where: { $0.weekday == weekday && !$0.isRest })?.routine {
            return scheduled
        }
        let routines = (try? context.fetch(FetchDescriptor<Routine>())) ?? []
        return routines.first { $0.scheduledWeekdays.contains(weekday) }
    }

    static func macroTotals(for date: Date, context: ModelContext) -> (kcal: Double, protein: Double, carbs: Double, fat: Double) {
        macros(for: date, context: context, eatenOnly: true)
    }

    static func plannedMacroTotals(for date: Date, context: ModelContext) -> (kcal: Double, protein: Double, carbs: Double, fat: Double) {
        macros(for: date, context: context, eatenOnly: false)
    }

    private static func macros(
        for date: Date,
        context: ModelContext,
        eatenOnly: Bool
    ) -> (kcal: Double, protein: Double, carbs: Double, fat: Double) {
        let plan = dayPlan(for: date, context: context)
        var kcal = 0.0, protein = 0.0, carbs = 0.0, fat = 0.0
        for meal in plan.plannedMeals {
            if eatenOnly && !meal.isEaten { continue }
            let macros = mealMacros(meal)
            kcal += macros.kcal
            protein += macros.protein
            carbs += macros.carbs
            fat += macros.fat
        }
        return (kcal, protein, carbs, fat)
    }

    static func mealMacros(_ planned: PlannedMeal) -> (kcal: Double, protein: Double, carbs: Double, fat: Double) {
        var kcal = 0.0, protein = 0.0, carbs = 0.0, fat = 0.0
        if let m = planned.meal {
            for ing in m.ingredients {
                guard let food = ing.food else { continue }
                let s = ing.servings * planned.servings
                kcal += food.kcal * s
                protein += food.protein * s
                carbs += food.carbs * s
                fat += food.fat * s
            }
        } else if let food = planned.food {
            let s = planned.servings
            kcal = food.kcal * s
            protein = food.protein * s
            carbs = food.carbs * s
            fat = food.fat * s
        }
        return (kcal, protein, carbs, fat)
    }
}
