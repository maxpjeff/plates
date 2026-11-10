import Foundation

enum PerformanceUnit: String, Codable, CaseIterable {
    case seconds, meters, kilograms, pounds
}

enum PerformanceContext: String, Codable, CaseIterable {
    case meet, training, test
}

enum Goal: String, Codable, CaseIterable, Identifiable {
    case buildMuscle, loseFat, getStronger, feelHealthier
    var id: String { rawValue }
    var label: String {
        switch self {
        case .buildMuscle: "Build muscle"
        case .loseFat: "Lose fat"
        case .getStronger: "Get stronger"
        case .feelHealthier: "Feel healthier"
        }
    }
}

enum Sex: String, Codable, CaseIterable {
    case male, female, preferNotToSay
}

enum DetailLevel: String, Codable, CaseIterable {
    case simple, balanced, dialedIn
}

enum LiftExperience: String, Codable, CaseIterable {
    case new, someYears, many
}

enum WeightUnit: String, Codable, CaseIterable {
    case lb, kg
}

enum MuscleGroup: String, Codable, CaseIterable {
    case back, chest, legs, shoulders, arms, core, glutes, fullBody

    var friendlyName: String {
        switch self {
        case .back: "Back"
        case .chest: "Chest"
        case .legs: "Legs"
        case .shoulders: "Shoulders"
        case .arms: "Arms"
        case .core: "Core"
        case .glutes: "Glutes"
        case .fullBody: "Full body"
        }
    }
}

/// Movement / pattern role (can be multiple per exercise).
enum MovementPattern: String, Codable, CaseIterable, Identifiable, Hashable {
    var id: String { rawValue }
    case squat, hinge, lunge, horizontalPush, verticalPush, horizontalPull, verticalPull, carry, core, isolation
    case easyRun, longRun, tempoRun, intervalRun, sprint

    var label: String {
        switch self {
        case .squat: "Squat"
        case .hinge: "Hinge"
        case .lunge: "Lunge"
        case .horizontalPush: "Horizontal push"
        case .verticalPush: "Vertical push"
        case .horizontalPull: "Horizontal pull"
        case .verticalPull: "Vertical pull"
        case .carry: "Carry"
        case .core: "Core"
        case .isolation: "Isolation"
        case .easyRun: "Easy run"
        case .longRun: "Long run"
        case .tempoRun: "Tempo run"
        case .intervalRun: "Intervals"
        case .sprint: "Sprint"
        }
    }

    static var liftFilters: [MovementPattern] {
        [.squat, .hinge, .lunge, .horizontalPush, .verticalPush, .horizontalPull, .verticalPull, .carry, .core, .isolation]
    }

    static var runFilters: [MovementPattern] {
        [.easyRun, .longRun, .tempoRun, .intervalRun, .sprint]
    }
}

/// Finer muscle filters for exercise picker (maps to tags on exercises).
enum MuscleFilter: String, CaseIterable, Identifiable, Hashable {
    case chest, shoulders, back, biceps, triceps, quads, hamstrings, glutes, calves, core

    var id: String { rawValue }

    var label: String { rawValue.capitalized }

    func matches(_ exercise: Exercise) -> Bool {
        if exercise.muscleDisplayTags.contains(where: { $0.localizedCaseInsensitiveContains(label) }) {
            return true
        }
        switch self {
        case .chest: return exercise.primaryMuscle == .chest || exercise.secondaryMuscles.contains(.chest)
        case .shoulders: return exercise.primaryMuscle == .shoulders || exercise.secondaryMuscles.contains(.shoulders)
        case .back: return exercise.primaryMuscle == .back || exercise.secondaryMuscles.contains(.back)
        case .biceps, .triceps: return exercise.primaryMuscle == .arms
        case .quads, .hamstrings, .calves: return exercise.primaryMuscle == .legs
        case .glutes: return exercise.primaryMuscle == .glutes || exercise.secondaryMuscles.contains(.glutes)
        case .core: return exercise.primaryMuscle == .core || exercise.secondaryMuscles.contains(.core)
        }
    }
}

enum Equipment: String, Codable, CaseIterable {
    case barbell, dumbbell, machine, cable, bodyweight, bodyweightLoaded
}

enum DayType: String, Codable, CaseIterable {
    case heavy, standard, light
}

enum FoodSource: String, Codable, CaseIterable {
    case seed, usda, openFoodFacts, user, aiEstimate
}

enum GroceryAisle: String, Codable, CaseIterable {
    case protein, produce, grains, dairy, pantry, frozen, other
}

enum MealTimingTag: String, Codable, CaseIterable {
    case pre, post, breakfast, lunch, dinner, snack
}

enum WeightSource: String, Codable {
    case manual, healthKit
}

enum FoodLogSource: String, Codable {
    case planned, unplanned
}
