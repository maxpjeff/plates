import Foundation

struct DayAccountabilityInput: Equatable {
    let date: Date
    let isTrainingDay: Bool
    let workoutCompleted: Bool
    let proteinRatio: Double
    let fuelAdherenceRatio: Double
}

struct DayAccountabilityResult: Equatable {
    let date: Date
    let score: Int
    let metPlan: Bool
}

struct MonthlyAccountabilitySummary: Equatable {
    let monthStart: Date
    let daysMetPlan: Int
    let daysInMonth: Int
    let averageScore: Int
    let previousMonthDaysMet: Int
    let dailyResults: [DayAccountabilityResult]
}

enum AccountabilityEngine {
    /// 0–100 score for a single day (fuel + training alignment).
    static func dayScore(_ input: DayAccountabilityInput) -> Int {
        var score = 0.0
        if input.isTrainingDay {
            score += input.workoutCompleted ? 45 : 0
        } else {
            score += 25
        }

        let protein = clamp(input.proteinRatio, 0, 1.4)
        if protein >= 0.85 { score += 35 }
        else if protein >= 0.65 { score += 22 }
        else if protein >= 0.45 { score += 10 }

        let fuel = clamp(input.fuelAdherenceRatio, 0, 1.5)
        if fuel >= 0.75 && fuel <= 1.15 { score += 20 }
        else if fuel >= 0.55 && fuel <= 1.3 { score += 12 }

        return Int(min(100, score.rounded()))
    }

    static func metPlan(score: Int) -> Bool {
        score >= 68
    }

    static func evaluate(_ input: DayAccountabilityInput) -> DayAccountabilityResult {
        let score = dayScore(input)
        return DayAccountabilityResult(date: input.date, score: score, metPlan: metPlan(score: score))
    }

    static func monthlySummary(
        monthContaining reference: Date,
        inputs: [DayAccountabilityInput],
        previousMonthInputs: [DayAccountabilityInput],
        calendar: Calendar = .current
    ) -> MonthlyAccountabilitySummary {
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: reference)) ?? reference
        let range = calendar.range(of: .day, in: .month, for: start) ?? 1..<31
        let daysInMonth = range.count

        let results = inputs.map { evaluate($0) }
        let met = results.filter(\.metPlan).count
        let avg = results.isEmpty ? 0 : results.map(\.score).reduce(0, +) / results.count

        let prevMet = previousMonthInputs
            .map { evaluate($0).metPlan }
            .filter { $0 }
            .count

        return MonthlyAccountabilitySummary(
            monthStart: start,
            daysMetPlan: met,
            daysInMonth: daysInMonth,
            averageScore: avg,
            previousMonthDaysMet: prevMet,
            dailyResults: results.sorted { $0.date < $1.date }
        )
    }

    private static func clamp(_ value: Double, _ low: Double, _ high: Double) -> Double {
        min(high, max(low, value))
    }
}
