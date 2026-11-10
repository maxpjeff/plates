import Foundation

enum HybridBlockType: String, Codable, CaseIterable, Identifiable {
    case lift, sprint, hurdles, jumps, plyo, run, conditioning

    var id: String { rawValue }

    var label: String {
        switch self {
        case .lift: "Lift"
        case .sprint: "Sprint"
        case .hurdles: "Hurdles"
        case .jumps: "Jumps"
        case .plyo: "Plyo"
        case .run: "Run"
        case .conditioning: "Conditioning"
        }
    }
}

enum DayLoadLabel: String, Codable, CaseIterable {
    case high, moderate, low, rest

    var title: String {
        switch self {
        case .high: "High"
        case .moderate: "Moderate"
        case .low: "Low"
        case .rest: "Rest"
        }
    }
}

enum CNSIntensity: String, Codable, CaseIterable {
    case low, moderate, high
}

enum SprintStartType: String, Codable, CaseIterable {
    case blocks, threePoint, fly, standing
}

enum SprintFootwear: String, Codable, CaseIterable {
    case spikes, flats
}

enum TimingMethod: String, Codable, CaseIterable {
    case hand, fat, laser, camera
}

enum JumpEvent: String, Codable, CaseIterable {
    case longJump, tripleJump, highJump, poleVault

    var label: String {
        switch self {
        case .longJump: "Long jump"
        case .tripleJump: "Triple jump"
        case .highJump: "High jump"
        case .poleVault: "Pole vault"
        }
    }
}

enum RunKind: String, Codable, CaseIterable {
    case easy, tempo, long, intervals, race
}

enum MealSlotRole: String, Codable, CaseIterable {
    case breakfast, preSession, intraSession, postSession, dinner, snack, anytime

    var label: String {
        switch self {
        case .breakfast: "Breakfast"
        case .preSession: "Pre-session"
        case .intraSession: "Intra-session"
        case .postSession: "Post-session"
        case .dinner: "Dinner"
        case .snack: "Snack"
        case .anytime: "Anytime"
        }
    }
}

enum TrainingModality: String, Codable, CaseIterable, Identifiable {
    case sprintsHurdles, jumps, lifting, distance, conditioning

    var id: String { rawValue }

    var label: String {
        switch self {
        case .sprintsHurdles: "Sprints & hurdles"
        case .jumps: "Jumps"
        case .lifting: "Lifting"
        case .distance: "Distance running"
        case .conditioning: "Conditioning"
        }
    }
}

struct HybridLiftSet: Codable, Equatable {
    var weightKg: Double
    var reps: Int
    var rir: Int?
    var isWarmup: Bool
}

struct HybridTimedRep: Codable, Equatable {
    var seconds: Double
    var timing: TimingMethod
    var windMS: Double?
    var quality: Int?
}

struct HybridHurdleRep: Codable, Equatable {
    var timeToH1Sec: Double?
    var totalSec: Double?
    var hits: Int
    var knocks: Int
}

struct HybridJumpAttempt: Codable, Equatable {
    var markM: Double?
    var isFoul: Bool
    var windMS: Double?
}

struct HybridItemSpec: Codable, Equatable {
    enum Kind: String, Codable {
        case lift, sprint, hurdles, jumps, plyo, run, conditioning
    }

    var kind: Kind

    // Lift
    var exerciseName: String?
    var exerciseId: UUID?
    var sets: Int?
    var repsMin: Int?
    var repsMax: Int?
    var loadLabel: String?

    // Sprint
    var distanceM: Double?
    var sprintReps: Int?
    var sprintSets: Int?
    var intensityPct: Int?
    var startType: SprintStartType?
    var footwear: SprintFootwear?
    var restSec: Int?

    // Hurdles
    var hurdleCount: Int?
    var hurdleHeightIn: Double?
    var hurdleSpacingM: Double?
    var approachStrides: Int?
    var hurdleReps: Int?

    // Jumps
    var jumpEvent: JumpEvent?
    var jumpAttempts: Int?
    var jumpApproachStrides: Int?

    // Plyo
    var plyoDrill: String?
    var contactsPerSet: Int?
    var plyoSets: Int?
    var plyoTier: CNSIntensity?

    // Run
    var runKind: RunKind?
    var runDistanceM: Double?
    var runDurationSec: Int?

    // Conditioning
    var conditioningFormat: String?
    var conditioningRounds: Int?
}

struct HybridItemResult: Codable, Equatable {
    var liftSets: [HybridLiftSet]?
    var sprintReps: [HybridTimedRep]?
    var hurdleReps: [HybridHurdleRep]?
    var jumpAttempts: [HybridJumpAttempt]?
    var plyoContacts: Int?
    var runDistanceM: Double?
    var runDurationSec: Int?
    var conditioningRounds: Int?
}

struct DayLoadSnapshot: Equatable {
    let date: Date
    let energyKcal: Double
    let neuralPoints: Double
    let label: DayLoadLabel
    let isPlanned: Bool
}
