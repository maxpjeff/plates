import Foundation

enum ProgressionEngine {
    static func estimatedOneRepMaxKg(weightKg: Double, reps: Int) -> Double? {
        guard reps > 0, reps <= 12 else { return nil }
        return weightKg * (1 + Double(reps) / 30)
    }

    static func isPROneRepMax(newEstimate: Double, previousBest: Double?) -> Bool {
        guard let previousBest else { return true }
        return newEstimate > previousBest + 0.01
    }

    static func incrementKg(isLowerBody: Bool, units: WeightUnit) -> Double {
        switch units {
        case .lb: return isLowerBody ? 10 * 0.453592 : 5 * 0.453592
        case .kg: return isLowerBody ? 5 : 2.5
        }
    }

    static func roundWeightKg(_ kg: Double, units: WeightUnit) -> Double {
        let step = units == .kg ? 1.25 : 2.5 * 0.453592
        return (kg / step).rounded() * step
    }

    static func nextTarget(
        repMin: Int,
        repMax: Int,
        lastSession: SessionPerformance?,
        priorSession: SessionPerformance?,
        lastWeightKg: Double,
        isLowerBody: Bool,
        units: WeightUnit,
        isDeloadWeek: Bool
    ) -> ProgressionTarget {
        if isDeloadWeek {
            let workingSets = max(1, (lastSession?.sets.filter { !$0.isWarmup }.count ?? 3) * 60 / 100)
            return ProgressionTarget(
                weightKg: lastWeightKg,
                repMin: repMin,
                repMax: repMax,
                note: "Deload: \(workingSets) sets at \(Int(lastWeightKg)) kg"
            )
        }

        let working = lastSession?.sets.filter { !$0.isWarmup } ?? []
        let allHitMax = !working.isEmpty && working.allSatisfy { $0.reps >= repMax && $0.weightKg >= lastWeightKg - 0.01 }

        if allHitMax {
            let bump = incrementKg(isLowerBody: isLowerBody, units: units)
            let next = roundWeightKg(lastWeightKg + bump, units: units)
            return ProgressionTarget(
                weightKg: next,
                repMin: repMin,
                repMax: repMax,
                note: "Add weight — all sets hit \(repMax) reps"
            )
        }

        let belowMinTwice = sessionsBelowMin(last: lastSession, prior: priorSession, repMin: repMin, weightKg: lastWeightKg)
        if belowMinTwice {
            let reduced = roundWeightKg(lastWeightKg * 0.9, units: units)
            return ProgressionTarget(
                weightKg: reduced,
                repMin: repMin,
                repMax: repMax,
                note: "Suggest −10% — reps dipped two sessions"
            )
        }

        return ProgressionTarget(
            weightKg: lastWeightKg,
            repMin: repMin,
            repMax: repMax,
            note: "Same weight — aim for +1 rep"
        )
    }

    private static func sessionsBelowMin(last: SessionPerformance?, prior: SessionPerformance?, repMin: Int, weightKg: Double) -> Bool {
        func sessionBelow(_ session: SessionPerformance?) -> Bool {
            guard let session else { return false }
            let working = session.sets.filter { !$0.isWarmup && abs($0.weightKg - weightKg) < 0.01 }
            guard !working.isEmpty else { return false }
            return working.contains { $0.reps < repMin }
        }
        return sessionBelow(last) && sessionBelow(prior)
    }

    static func formatSetTarget(weightKg: Double, sets: Int, repMin: Int, repMax: Int, units: WeightUnit) -> String {
        let w = UnitFormat.displayWeight(weightKg, units: units)
        if repMin == repMax {
            return "\(sets) × \(repMin) @ \(w)"
        }
        return "\(sets) × \(repMin)–\(repMax) @ \(w)"
    }
}
