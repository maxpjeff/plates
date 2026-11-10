import Foundation

enum TargetsEngine {
    static func bmrKgCmAge(sex: Sex, weightKg: Double, heightCm: Double, ageYears: Int) -> Double {
        let base = 10 * weightKg + 6.25 * heightCm - 5 * Double(ageYears)
        switch sex {
        case .male: return base + 5
        case .female: return base - 161
        case .preferNotToSay: return base - 78
        }
    }

    static func activityMultiplier(trainingDaysPerWeek: Int) -> Double {
        switch trainingDaysPerWeek {
        case ...2: return 1.40
        case 3...4: return 1.55
        default: return 1.70
        }
    }

    static func goalCalorieMultiplier(goals: [Goal]) -> Double {
        let set = Set(goals)
        if set.contains(.loseFat) && set.contains(.buildMuscle) { return 0.95 }
        if set.contains(.loseFat) { return 0.85 }
        if set.contains(.buildMuscle) { return 1.08 }
        return 1.00
    }

    static func maintenanceKcal(bmr: Double, trainingDaysPerWeek: Int) -> Double {
        bmr * activityMultiplier(trainingDaysPerWeek: trainingDaysPerWeek)
    }

    static func averageGoalKcal(maintenance: Double, goals: [Goal]) -> Double {
        maintenance * goalCalorieMultiplier(goals: goals)
    }

    static func calorieFloor(bmr: Double) -> Double {
        max(1.1 * bmr, 1_400)
    }

    static func dayTypeMultiplier(_ type: DayType) -> Double {
        switch type {
        case .heavy: return 1.08
        case .standard: return 1.04
        case .light: return 1.00
        }
    }

    static func restDayMultiplier() -> Double { 0.92 }

    static func proteinPerKg(for detail: DetailLevel, override: Double?) -> Double {
        if let override { return min(2.6, max(1.2, override)) }
        switch detail {
        case .simple: return 1.4
        case .balanced: return 1.6
        case .dialedIn: return 2.0
        }
    }

    static func dailyTargets(
        profile: UserProfile,
        trendWeightKg: Double,
        weekPlan: [WeekDayTargetInput],
        date: Date,
        adaptiveMaintenanceKcal: Double? = nil
    ) -> DailyTargetsResult {
        let age = Calendar.current.dateComponents([.year], from: profile.birthDate, to: date).year ?? 30
        let bmr = bmrKgCmAge(sex: profile.sex, weightKg: trendWeightKg, heightCm: profile.heightCm, ageYears: age)
        let maintenance = adaptiveMaintenanceKcal ?? maintenanceKcal(bmr: bmr, trainingDaysPerWeek: profile.trainingDaysPerWeek)
        let avgGoal = averageGoalKcal(maintenance: maintenance, goals: profile.goals)
        let floor = calorieFloor(bmr: bmr)

        let weekday = Calendar.current.component(.weekday, from: date)
        let todayInput = weekPlan.first { $0.weekday == weekday }
        let todayType = todayInput?.dayType

        let trainingDays = weekPlan.sorted { $0.weekday < $1.weekday }
        let trainingMultipliers = trainingDays.map { dayTypeMultiplier($0.dayType) }
        let restSlots = max(0, 7 - trainingDays.count)
        let sumMultipliers = trainingMultipliers.reduce(0, +) + Double(restSlots) * restDayMultiplier()
        if sumMultipliers <= 0 {
            return DailyTargetsResult(
                date: date,
                dayType: .light,
                kcal: Int(max(avgGoal, floor)),
                proteinG: Int((proteinPerKg(for: profile.foodDetail, override: profile.proteinPerKg) * trendWeightKg).rounded()),
                carbsG: 0,
                fatG: 0,
                reason: "Add a weekly split to personalize training-day cycling."
            )
        }
        let weeklyBudget = avgGoal * 7

        let todayMultiplier: Double
        if let todayType {
            todayMultiplier = dayTypeMultiplier(todayType)
        } else {
            todayMultiplier = restDayMultiplier()
        }

        var dayKcal = weeklyBudget * (todayMultiplier / max(sumMultipliers, 0.01))
        dayKcal = (dayKcal / 10).rounded() * 10
        dayKcal = max(dayKcal, floor)

        let proteinG = Int((proteinPerKg(for: profile.foodDetail, override: profile.proteinPerKg) * trendWeightKg).rounded())
        let fatG = max(Int((0.6 * trendWeightKg).rounded()), Int((0.25 * avgGoal / 9).rounded()))

        var fatUsed = fatG
        var carbsG = Int(((dayKcal - Double(proteinG) * 4 - Double(fatUsed) * 9) / 4).rounded())
        if carbsG < 50 {
            fatUsed = max(Int((0.5 * trendWeightKg).rounded()), fatG - 10)
            carbsG = Int(((dayKcal - Double(proteinG) * 4 - Double(fatUsed) * 9) / 4).rounded())
        }
        carbsG = max(0, carbsG)

        let reason = targetReason(todayType: todayType, dayKcal: Int(dayKcal), avgGoal: Int(avgGoal))

        return DailyTargetsResult(
            date: date,
            dayType: todayType ?? .light,
            kcal: Int(dayKcal),
            proteinG: proteinG,
            carbsG: carbsG,
            fatG: fatUsed,
            reason: reason
        )
    }

    static func targetReason(todayType: DayType?, dayKcal: Int, avgGoal: Int) -> String {
        guard let todayType else {
            return "Rest day: lower carbs, same protein."
        }
        let delta = dayKcal - avgGoal
        if delta > 40 {
            switch todayType {
            case .heavy:
                return "+\(delta) kcal vs your daily average, because you're training heavy today."
            case .standard:
                return "+\(delta) kcal vs your daily average for a standard training day."
            case .light:
                return "Training day targets with a modest calorie bump."
            }
        }
        if delta < -40 {
            return "Rest day: lower carbs, same protein."
        }
        return "Targets aligned with today's training load."
    }

    static func activityBonusCarbsKcal(todayActiveKcal: Double, average14Day: Double) -> Int {
        let excess = todayActiveKcal - average14Day
        guard excess >= 300 else { return 0 }
        let bonus = min(250, excess * 0.5)
        return Int(bonus.rounded())
    }
}
