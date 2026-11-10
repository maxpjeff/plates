import Foundation

enum DayLoadEngine {
    struct BlockLoadInput: Equatable {
        let type: HybridBlockType
        let spec: HybridItemSpec
        let result: HybridItemResult?
        let durationMinutes: Double
        let bodyWeightKg: Double
    }

    static func load(for input: BlockLoadInput) -> (energyKcal: Double, neural: Double) {
        let energy = energyKcal(for: input)
        let neural = neuralPoints(for: input)
        return (energy, neural)
    }

    static func dayLoad(
        date: Date,
        blocks: [BlockLoadInput],
        isPlanned: Bool,
        neuralThresholds: NeuralThresholds = .default
    ) -> DayLoadSnapshot {
        var energy = 0.0
        var neural = 0.0
        for block in blocks {
            let part = load(for: block)
            energy += part.energyKcal
            neural += part.neural
        }
        let label = label(forNeuralPoints: neural, thresholds: neuralThresholds)
        return DayLoadSnapshot(
            date: date,
            energyKcal: energy,
            neuralPoints: neural,
            label: label,
            isPlanned: isPlanned
        )
    }

    struct NeuralThresholds: Equatable {
        var high: Double
        var moderate: Double
        var low: Double

        static let `default` = NeuralThresholds(high: 25, moderate: 12, low: 5)
    }

    static func label(forNeuralPoints points: Double, thresholds: NeuralThresholds = .default) -> DayLoadLabel {
        if points >= thresholds.high { return .high }
        if points >= thresholds.moderate { return .moderate }
        if points >= thresholds.low { return .low }
        return .rest
    }

    private static func energyKcal(for input: BlockLoadInput) -> Double {
        let met = met(for: input.type)
        return met * input.bodyWeightKg * (input.durationMinutes / 60)
    }

    private static func met(for type: HybridBlockType) -> Double {
        switch type {
        case .lift: 5.5
        case .sprint: 9.0
        case .hurdles: 8.5
        case .jumps: 7.5
        case .plyo: 6.5
        case .run: 8.0
        case .conditioning: 7.0
        }
    }

    private static func neuralPoints(for input: BlockLoadInput) -> Double {
        let spec = input.spec
        let result = input.result
        switch input.type {
        case .sprint:
            let distance = spec.distanceM ?? 30
            let reps = spec.sprintReps ?? 1
            let sets = spec.sprintSets ?? 1
            let intensity = Double(spec.intensityPct ?? 90) / 100
            if intensity >= 0.9 {
                return (distance * Double(reps * sets) / 10) * intensity
            }
            return (distance * Double(reps * sets) / 20)
        case .hurdles:
            let reps = spec.hurdleReps ?? result?.hurdleReps?.count ?? 1
            return Double(reps) * 3
        case .jumps:
            let attempts = spec.jumpAttempts ?? result?.jumpAttempts?.count ?? 1
            let strides = spec.jumpApproachStrides ?? 16
            let per = strides >= 14 ? 4.0 : 2.0
            return Double(attempts) * per
        case .plyo:
            let contacts = result?.plyoContacts ?? (spec.contactsPerSet ?? 0) * (spec.plyoSets ?? 1)
            let tier = spec.plyoTier ?? .moderate
            let weight: Double = switch tier {
            case .low: 0.1
            case .moderate: 0.25
            case .high: 0.5
            }
            return Double(contacts) * weight
        case .lift:
            let sets = result?.liftSets?.filter { ($0.rir ?? 3) <= 3 && !$0.isWarmup }.count
                ?? (spec.sets ?? 3)
            return Double(sets) * 2
        case .run:
            let minutes = Double(result?.runDurationSec ?? spec.runDurationSec ?? Int(input.durationMinutes * 60)) / 60
            let kind = spec.runKind ?? .easy
            if kind == .tempo || kind == .intervals || kind == .race {
                return minutes
            }
            return minutes * 0.3
        case .conditioning:
            let rounds = Double(result?.conditioningRounds ?? spec.conditioningRounds ?? 3)
            return rounds * 2
        }
    }
}
