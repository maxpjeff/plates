import Foundation

struct DailyScoreInput: Equatable {
    var sessionLogged: Bool
    var goalSetAndReflected: Bool
    var goalHit: Bool
    var proteinTargetHit: Bool
    var mealsLogged: Bool
    var hasSessionGoal: Bool
    var isRestDay: Bool
}

enum PlatesScoreEngine {
    static func dailyScore(_ input: DailyScoreInput) -> Int {
        let sessionDone = input.sessionLogged || input.isRestDay
        var sessionPoints = sessionDone ? 40 : 0
        if !input.hasSessionGoal, sessionDone {
            sessionPoints = 50
        }

        let goalReflect = input.hasSessionGoal && input.goalSetAndReflected ? 5 : 0
        let goalHitPts = input.hasSessionGoal && input.goalHit ? 5 : 0
        let protein = input.proteinTargetHit ? 30 : 0
        let meals = input.mealsLogged ? 20 : 0

        return sessionPoints + goalReflect + goalHitPts + protein + meals
    }

    static func weeklyScore(dayScores: [Int]) -> Int {
        guard !dayScores.isEmpty else { return 0 }
        let avg = Double(dayScores.reduce(0, +)) / Double(dayScores.count)
        return Int(avg.rounded())
    }

    static func completionPercent(score: Int) -> Int {
        min(100, max(0, score))
    }

    enum WeekMessage {
        case belowBest(gap: Int)
        case atOrAboveBest(score: Int)
        case firstWeek
    }

    static func weekMessage(score: Int, bestWeek: Int?, isFirstWeek: Bool) -> (title: String, subtitle: String) {
        if isFirstWeek {
            return ("Your first Plates Score.", "Every full day builds it.")
        }
        if let bestWeek, score >= bestWeek {
            return ("New best week: \(score).", "Keep this one rolling.")
        }
        let gap = max(0, (bestWeek ?? score) - score)
        if gap == 0, bestWeek != nil {
            return ("New best week: \(score).", "Keep this one rolling.")
        }
        return (
            "\(gap) points from your best week.",
            "Stack a few full days and set a new high."
        )
    }
}

enum CalendarDayShade {
    static func opacity(forCompletionPercent percent: Int) -> Double {
        switch percent {
        case 100: 1.0
        case 75...99: 0.6
        case 40...74: 0.38
        case 1...39: 0.2
        default: 0
        }
    }
}
