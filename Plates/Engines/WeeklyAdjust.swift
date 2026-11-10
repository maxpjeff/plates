import Foundation

enum WeeklyAdjustEngine {
    static func adjust(
        previousMaintenanceKcal: Double,
        averageDailyIntakeKcal: Double,
        trendChangeKg: Double,
        daysInSample: Int,
        daysWithFoodLogged: Int,
        weighInCount: Int,
        goal: Goal
    ) -> WeeklyAdjustResult {
        guard daysWithFoodLogged >= 10, weighInCount >= 8, daysInSample >= 14 else {
            return WeeklyAdjustResult(
                applied: false,
                newMaintenanceKcal: Int(previousMaintenanceKcal.rounded()),
                deltaKcal: 0,
                summary: "Not enough food logs or weigh-ins yet to adjust targets."
            )
        }

        let estimatedChangeFromWeight = trendChangeKg * 7_700 / Double(daysInSample)
        let estimatedMaintenance = averageDailyIntakeKcal - estimatedChangeFromWeight
        var blended = 0.5 * estimatedMaintenance + 0.5 * previousMaintenanceKcal
        let rawDelta = blended - previousMaintenanceKcal
        let cappedDelta = min(150, max(-150, rawDelta))
        blended = previousMaintenanceKcal + cappedDelta

        let trendLb = trendChangeKg * 2.20462
        let summary: String
        if abs(trendLb) < 0.05 {
            summary = "Your weight trend held steady. Daily targets stay the same for now."
        } else if trendLb < 0 {
            summary = String(format: "Your trend dropped %.1f lb this week. Daily targets are down %d kcal.", abs(trendLb), Int(abs(cappedDelta)))
        } else {
            summary = String(format: "Your trend rose %.1f lb this week. Daily targets are up %d kcal.", trendLb, Int(abs(cappedDelta)))
        }

        _ = goal // reserved for target-rate copy in UI

        return WeeklyAdjustResult(
            applied: true,
            newMaintenanceKcal: Int(blended.rounded()),
            deltaKcal: Int(cappedDelta.rounded()),
            summary: summary
        )
    }
}
