import Foundation
import SwiftData

enum ExerciseMetadataService {
    static func applyMovementPatterns(context: ModelContext) {
        let exercises = (try? context.fetch(FetchDescriptor<Exercise>())) ?? []
        for exercise in exercises where (exercise.movementPatternsRaw ?? []).isEmpty {
            exercise.movementPatternsRaw = inferPatterns(for: exercise.name).map(\.rawValue)
        }
    }

    static func ensureVariationGroups(context: ModelContext) {
        let count = (try? context.fetchCount(FetchDescriptor<ExerciseVariationGroup>())) ?? 0
        guard count == 0 else { return }

        let exercises = (try? context.fetch(FetchDescriptor<Exercise>())) ?? []
        func names(_ keys: [String]) -> [Exercise] {
            keys.compactMap { key in exercises.first { $0.name.localizedCaseInsensitiveContains(key) } }
        }

        let groups: [(String, [String])] = [
            ("Squat variation", ["Barbell Squat", "Front Squat", "Hack Squat", "Goblet Squat"]),
            ("Hinge variation", ["Deadlift", "Romanian Deadlift", "Good Morning"]),
            ("Horizontal push variation", ["Barbell Bench", "Incline", "Dumbbell Press"]),
            ("Vertical pull variation", ["Pull-Up", "Lat Pulldown", "Chin-Up"]),
            ("Row variation", ["Barbell Row", "Dumbbell Row", "Cable Row"]),
        ]

        for (title, keys) in groups {
            let members = names(keys)
            guard !members.isEmpty else { continue }
            context.insert(ExerciseVariationGroup(name: title, exercises: members))
        }
    }

    private static func inferPatterns(for name: String) -> [MovementPattern] {
        let n = name.lowercased()
        var patterns: [MovementPattern] = []
        if n.contains("squat") || n.contains("leg press") { patterns.append(.squat) }
        if n.contains("deadlift") || n.contains("romanian") || n.contains("good morning") { patterns.append(.hinge) }
        if n.contains("lunge") || n.contains("split squat") { patterns.append(.lunge) }
        if n.contains("bench") || n.contains("push-up") || n.contains("dip") || n.contains("fly") { patterns.append(.horizontalPush) }
        if n.contains("overhead") || n.contains("press") && !n.contains("bench") && !n.contains("leg") { patterns.append(.verticalPush) }
        if n.contains("row") { patterns.append(.horizontalPull) }
        if n.contains("pull") || n.contains("chin") { patterns.append(.verticalPull) }
        if n.contains("carry") || n.contains("farmer") { patterns.append(.carry) }
        if n.contains("plank") || n.contains("crunch") || n.contains("ab ") || n.contains("leg raise") || n.contains("wheel") {
            patterns.append(.core)
        }
        if n.contains("curl") || n.contains("extension") || n.contains("raise") && !n.contains("leg") {
            patterns.append(.isolation)
        }
        if n.contains("sprint") || n.contains("100m") || n.contains("200m") || n.contains("400m") {
            patterns.append(.sprint)
        }
        if n.contains("interval") || n.contains("repeat") && n.contains("run") {
            patterns.append(.intervalRun)
        }
        if n.contains("tempo run") || n.contains("tempo ") {
            patterns.append(.tempoRun)
        }
        if n.contains("long run") || n.contains("easy run") || n.contains("recovery run") {
            patterns.append(n.contains("long") ? .longRun : .easyRun)
        }
        if n.contains(" run") || n.contains("jog") || n.contains("mile") {
            if !patterns.contains(where: { MovementPattern.runFilters.contains($0) }) {
                patterns.append(.easyRun)
            }
        }
        if patterns.isEmpty { patterns.append(.isolation) }
        return Array(Set(patterns))
    }

    static func ensureRunningExercises(context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<Exercise>())) ?? []
        let names = Set(existing.map(\.name))
        let seeds: [(String, MuscleGroup, [MovementPattern], Bool)] = [
            ("Easy Run", .fullBody, [.easyRun], true),
            ("Long Run", .fullBody, [.longRun], true),
            ("Tempo Run", .fullBody, [.tempoRun], true),
            ("Interval Run", .fullBody, [.intervalRun], true),
            ("Hill Repeats", .legs, [.intervalRun], true),
            ("Track Sprint — 100m", .legs, [.sprint], true),
            ("Track Sprint — 200m", .legs, [.sprint], true),
            ("Track Sprint — 400m", .legs, [.sprint], true),
            ("Strides", .legs, [.sprint], true),
            ("Fartlek", .fullBody, [.intervalRun], true),
        ]
        for (name, muscle, patterns, lower) in seeds where !names.contains(name) {
            let ex = Exercise(
                name: name,
                primaryMuscle: muscle,
                secondaryMuscles: muscle == .legs ? [.glutes] : [],
                equipment: .bodyweight,
                movementPatterns: patterns,
                isLowerBody: lower
            )
            context.insert(ex)
        }
    }
}
