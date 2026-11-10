import Foundation

enum FuelTargetsEngine {
    /// Adjusts base targets using hybrid day load (energy + neural label).
    static func adjust(
        base: DailyTargetsResult,
        load: DayLoadSnapshot?,
        profile: UserProfile
    ) -> DailyTargetsResult {
        guard let load else { return base }
        let energyBonus = load.label == .rest ? 0 : Int(load.energyKcal.rounded())
        let kcal = base.kcal + energyBonus

        let proteinG = base.proteinG
        var carbsG = base.carbsG
        var fatG = base.fatG

        switch load.label {
        case .high:
            carbsG = Int((Double(base.carbsG) * 1.12).rounded())
        case .moderate:
            carbsG = Int((Double(base.carbsG) * 1.05).rounded())
        case .low:
            carbsG = Int((Double(base.carbsG) * 0.95).rounded())
        case .rest:
            carbsG = Int((Double(base.carbsG) * 0.88).rounded())
        }

        let proteinKcal = Double(proteinG) * 4
        let carbKcal = Double(carbsG) * 4
        let remaining = max(0, Double(kcal) - proteinKcal - carbKcal)
        fatG = max(0, Int((remaining / 9).rounded()))

        let reason = base.reason + " · \(load.label.title) day (+\(energyBonus) kcal session energy)."
        _ = profile
        return DailyTargetsResult(
            date: base.date,
            dayType: base.dayType,
            kcal: kcal,
            proteinG: proteinG,
            carbsG: carbsG,
            fatG: fatG,
            reason: reason
        )
    }
}
