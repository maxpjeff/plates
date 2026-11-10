import Foundation
import SwiftData

enum StarterSplit: String, CaseIterable, Identifiable {
    case fullBodyAB
    case pushPullLegs
    case upperLower
    case pplUpper

    var id: String { rawValue }

    var label: String {
        switch self {
        case .fullBodyAB: "Full body A / B"
        case .pushPullLegs: "Push / Pull / Legs"
        case .upperLower: "Upper / Lower ×2"
        case .pplUpper: "Push / Pull / Legs + Upper"
        }
    }

    static func recommended(for days: Int) -> StarterSplit {
        switch days {
        case ...2: return .fullBodyAB
        case 3: return .pushPullLegs
        case 4: return .upperLower
        default: return .pplUpper
        }
    }
}

enum OnboardingSplitBuilder {
    /// Replaces user routines with a starter split from onboarding choices.
    static func apply(
        split: StarterSplit,
        trainingDays: Int,
        context: ModelContext
    ) {
        let existingRoutines = (try? context.fetch(FetchDescriptor<Routine>())) ?? []
        for r in existingRoutines {
            context.delete(r)
        }
        let schedules = (try? context.fetch(FetchDescriptor<WeekSchedule>())) ?? []
        for s in schedules { context.delete(s) }

        let exercises = (try? context.fetch(FetchDescriptor<Exercise>())) ?? []
        guard !exercises.isEmpty else { return }

        func ex(_ name: String) -> Exercise? {
            exercises.first { $0.name.localizedCaseInsensitiveContains(name) }
        }

        switch split {
        case .fullBodyAB:
            makeRoutine(
                context: context,
                name: "Full body A", label: "Full A", color: .olive, type: .standard,
                weekdays: [2, 5],
                exerciseNames: ["Squat", "Bench", "Row"]
            )
            makeRoutine(
                context: context,
                name: "Full body B", label: "Full B", color: .navy, type: .standard,
                weekdays: [4],
                exerciseNames: ["Deadlift", "Overhead", "Pull-Up"]
            )
        case .pushPullLegs:
            makeRoutine(context: context, name: "Push day", label: "Push", color: .olive, type: .standard, weekdays: [2], exerciseNames: ["Bench", "Overhead", "Dips"])
            makeRoutine(context: context, name: "Pull day", label: "Pull", color: .wine, type: .heavy, weekdays: [4], exerciseNames: ["Deadlift", "Row", "Pull-Up"])
            makeRoutine(context: context, name: "Leg day", label: "Legs", color: .espresso, type: .heavy, weekdays: [6], exerciseNames: ["Squat", "Romanian", "Lunge"])
        case .upperLower:
            makeRoutine(context: context, name: "Upper", label: "Upper", color: .wine, type: .standard, weekdays: [2, 5], exerciseNames: ["Bench", "Row", "Overhead"])
            makeRoutine(context: context, name: "Lower", label: "Lower", color: .olive, type: .heavy, weekdays: [4, 7], exerciseNames: ["Squat", "Deadlift", "Lunge"])
        case .pplUpper:
            makeRoutine(context: context, name: "Push", label: "Push", color: .olive, type: .standard, weekdays: [2], exerciseNames: ["Bench", "Overhead"])
            makeRoutine(context: context, name: "Pull", label: "Pull", color: .wine, type: .heavy, weekdays: [3], exerciseNames: ["Deadlift", "Row"])
            makeRoutine(context: context, name: "Legs", label: "Legs", color: .espresso, type: .heavy, weekdays: [4], exerciseNames: ["Squat", "Romanian"])
            makeRoutine(context: context, name: "Upper", label: "Upper", color: .navy, type: .light, weekdays: [6], exerciseNames: ["Incline", "Lat Pulldown"])
        }

        _ = trainingDays // reserved for future day-count trimming
    }

    private static func makeRoutine(
        context: ModelContext,
        name: String,
        label: String,
        color: StickerColorName,
        type: DayType,
        weekdays: [Int],
        exerciseNames: [String]
    ) {
        let all = (try? context.fetch(FetchDescriptor<Exercise>())) ?? []
        let routine = Routine(name: name, shortLabel: label, stickerColor: color, dayType: type, scheduledWeekdays: weekdays)
        context.insert(routine)

        for (i, key) in exerciseNames.enumerated() {
            guard let exercise = all.first(where: { $0.name.localizedCaseInsensitiveContains(key) }) else { continue }
            let item = RoutineItem(exercise: exercise, order: i, sets: 3, repMin: 8, repMax: 12, restSeconds: 90)
            item.routine = routine
            context.insert(item)
        }

        for day in weekdays {
            context.insert(WeekSchedule(weekday: day, routine: routine))
        }
    }
}
