import Foundation

enum TargetCalculator {
    static func targets(for split: SplitDay, settings: TargetSettings) -> MacroTargets {
        if split.workout == "Rest" || split.workout.isEmpty {
            return MacroTargets(
                kcal: roundKcal(settings.baseKcal),
                protein: roundGrams(settings.protein),
                carbs: roundGrams(settings.baseCarbs),
                fat: roundGrams(settings.fat)
            )
        }

        let pct: Double
        let fat: Int
        switch split.effort {
        case .light:
            pct = 0.05
            fat = 65
        case .hard:
            pct = 0.15
            fat = 70
        case .medium, .none:
            pct = 0.10
            fat = 66
        }

        let addedKcal = Double(settings.baseKcal) * pct
        let totalKcal = roundKcal(settings.baseKcal + Int(addedKcal.rounded()))
        let addedCarbs = Int((addedKcal / 4).rounded())
        let totalCarbs = roundGrams(settings.baseCarbs + addedCarbs)

        return MacroTargets(
            kcal: totalKcal,
            protein: roundGrams(settings.protein),
            carbs: totalCarbs,
            fat: roundGrams(fat)
        )
    }

    static func roundKcal(_ value: Int) -> Int {
        Int((Double(value) / 10).rounded()) * 10
    }

    static func roundGrams(_ value: Int) -> Int {
        Int((Double(value) / 5).rounded()) * 5
    }
}
