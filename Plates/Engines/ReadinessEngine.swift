import Foundation

enum ReadinessEngine {
    static func score(
        hrvTodayMs: Double?,
        hrvBaselineMs: Double?,
        hrvStdMs: Double?,
        restingHRToday: Double?,
        restingHRBaseline: Double?,
        restingHRStd: Double?,
        sleepHours: Double?
    ) -> ReadinessResult {
        guard hrvTodayMs != nil || sleepHours != nil else {
            return ReadinessResult(score: 0, label: "", hasData: false)
        }

        var total = 50.0
        if let hrv = hrvTodayMs, let base = hrvBaselineMs, let std = hrvStdMs, std > 0 {
            let z = clamp((hrv - base) / std, -2, 2)
            total += 25 * z
        }
        if let hr = restingHRToday, let base = restingHRBaseline, let std = restingHRStd, std > 0 {
            let z = clamp((hr - base) / std, -2, 2)
            total -= 15 * z
        }
        if let sleep = sleepHours {
            total += 10 * clamp(sleep - 7.5, -2, 2)
        }

        let score = Int(clamp(total, 0, 100).rounded())
        let label: String
        switch score {
        case 67...: label = "Good to train hard"
        case 34..<67: label = "Train as planned"
        default: label = "Consider going lighter today"
        }
        return ReadinessResult(score: score, label: label, hasData: true)
    }

    private static func clamp(_ value: Double, _ min: Double, _ max: Double) -> Double {
        Swift.min(max, Swift.max(min, value))
    }
}
