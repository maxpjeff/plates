import Foundation
import SwiftData

@MainActor
enum CoachTips {
    static func tip(for date: Date, context: ModelContext) -> String? {
        let targets = PlatesDataStore.targets(for: date, context: context)
        let eaten = PlatesDataStore.macroTotals(for: date, context: context)
        let proteinGap = Double(targets.proteinG) - eaten.protein
        if proteinGap > 25 {
            return "You're about \(Int(proteinGap)) g short on protein vs today's plan — add a high-protein meal or snack."
        }
        let kcalGap = Double(targets.kcal) - eaten.kcal
        if kcalGap > 400 {
            return "Plenty of room left in today's fuel budget — don't skip post-workout carbs if you're training."
        }
        if kcalGap < -300 {
            return "You're above today's target — no stress; tomorrow's plan adjusts with your week."
        }
        return "You're on track with today's plan. Check off meals as you eat them."
    }
}
