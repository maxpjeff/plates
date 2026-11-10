import Foundation
import SwiftData

@MainActor
enum HybridSeedService {
    static func importIfNeeded(context: ModelContext) {
        seedTrackEvents(context: context)
        seedHybridTemplates(context: context)
        seedTodayHybridDemo(context: context)
        seedWeekHybridPlan(context: context)
        seedDemoPR(context: context)
    }

    private static func seedTrackEvents(context: ModelContext) {
        let count = (try? context.fetchCount(FetchDescriptor<TrackEvent>())) ?? 0
        guard count == 0 else { return }
        let events: [(String, String, PerformanceUnit)] = [
            ("30 m fly", "fly_30m", .seconds),
            ("60 m", "60m", .seconds),
            ("100 m", "100m", .seconds),
            ("110H", "110h", .seconds),
            ("Long jump", "lj", .meters),
            ("Triple jump", "tj", .meters),
            ("High jump", "hj", .meters),
        ]
        for (index, row) in events.enumerated() {
            context.insert(TrackEvent(name: row.0, code: row.1, unit: row.2, sortOrder: index))
        }
    }

    private static func seedDemoPR(context: ModelContext) {
        let records = (try? context.fetch(FetchDescriptor<PerformanceRecord>())) ?? []
        guard records.isEmpty else { return }
        let events = (try? context.fetch(FetchDescriptor<TrackEvent>())) ?? []
        guard let fly = events.first(where: { $0.code == "fly_30m" }) else { return }
        context.insert(
            PerformanceRecord(
                value: 2.90,
                unit: .seconds,
                context: .training,
                timing: .fat,
                isWindLegal: true,
                notes: "Demo PR",
                event: fly
            )
        )
    }

    private static func seedHybridTemplates(context: ModelContext) {
        let templates = (try? context.fetch(FetchDescriptor<TrainingSession>()))?.filter(\.isTemplate) ?? []
        guard templates.isEmpty else { return }

        insertTemplate(
            context: context,
            title: "Speed + Lower",
            blocks: speedLowerBlocks()
        )
        insertTemplate(
            context: context,
            title: "Speed + Upper",
            blocks: speedUpperBlocks()
        )
        insertTemplate(
            context: context,
            title: "Jumps + Pull",
            blocks: jumpsPullBlocks()
        )
        insertTemplate(
            context: context,
            title: "Hurdle technical",
            blocks: hurdleBlocks()
        )
    }

    private static func seedTodayHybridDemo(context: ModelContext) {
        let start = Calendar.current.startOfDay(for: Date())
        let existing = HybridDataStore.session(for: Date(), context: context)
        guard existing == nil else { return }

        var comps = Calendar.current.dateComponents([.year, .month, .day], from: start)
        comps.hour = 12
        comps.minute = 0
        let sessionStart = Calendar.current.date(from: comps)

        let session = TrainingSession(
            dayDate: start,
            title: "Speed + Lower",
            plannedStart: sessionStart,
            sortOrder: 0,
            isTemplate: false
        )
        context.insert(session)
        attachBlocks(speedLowerBlocks(), to: session, context: context)
        alignMealsToSession(session, context: context)
    }

    private static func seedWeekHybridPlan(context: ModelContext) {
        let schedules = (try? context.fetch(FetchDescriptor<WeekSchedule>())) ?? []
        guard schedules.allSatisfy({ $0.dayLoadLabelRaw == nil }) else { return }

        let plan: [(Int, String, DayLoadLabel, String?)] = [
            (1, "Rest day", .rest, "Walk + mobility"),
            (2, "Speed + Upper", .high, "Sprint · Lift"),
            (3, "Tempo run", .moderate, "Run · 4 mi"),
            (4, "Speed + Lower", .high, "Sprint · Plyo · Lift"),
            (5, "Mobility + core", .low, "Lift · PT-guided"),
            (6, "Jumps + Pull", .high, "Jumps · Lift"),
            (7, "Easy run", .low, "Run · 3 mi"),
        ]

        for (weekday, title, label, subtitle) in plan {
            if let existing = schedules.first(where: { $0.weekday == weekday }) {
                existing.dayLoadLabelRaw = label.rawValue
                existing.sessionTitle = title
                existing.cardioName = subtitle
                if label == .rest {
                    existing.isRest = true
                }
            } else {
                context.insert(
                    WeekSchedule(
                        weekday: weekday,
                        isRest: label == .rest,
                        dayLoadLabelRaw: label.rawValue,
                        sessionTitle: title
                    )
                )
            }
        }
    }

    private static func insertTemplate(context: ModelContext, title: String, blocks: [(HybridBlockType, String, HybridItemSpec, Int)]) {
        let session = TrainingSession(
            dayDate: .distantPast,
            title: title,
            isTemplate: true
        )
        context.insert(session)
        attachBlocks(blocks, to: session, context: context)
    }

    private static func attachBlocks(
        _ blocks: [(HybridBlockType, String, HybridItemSpec, Int)],
        to session: TrainingSession,
        context: ModelContext
    ) {
        for (index, block) in blocks.enumerated() {
            let trainingBlock = TrainingBlock(
                type: block.0,
                order: index,
                title: block.1,
                estimatedMinutes: block.3
            )
            trainingBlock.session = session
            context.insert(trainingBlock)
            let item = TrainingBlockItem(order: 0, restSec: block.2.restSec ?? 90, planned: block.2)
            item.block = trainingBlock
            context.insert(item)
        }
    }

    private static func speedLowerBlocks() -> [(HybridBlockType, String, HybridItemSpec, Int)] {
        [
            (.sprint, "Sprint", HybridItemSpec(
                kind: .sprint,
                distanceM: 30,
                sprintReps: 4,
                sprintSets: 1,
                intensityPct: 95,
                startType: .fly,
                footwear: .spikes,
                restSec: 240
            ), 25),
            (.plyo, "Plyo", HybridItemSpec(
                kind: .plyo,
                plyoDrill: "Pogos + bounds",
                contactsPerSet: 30,
                plyoSets: 2,
                plyoTier: .moderate
            ), 15),
            (.lift, "Lift", HybridItemSpec(
                kind: .lift,
                exerciseName: "Front squat",
                sets: 4,
                repsMin: 3,
                repsMax: 3,
                loadLabel: "Working weight"
            ), 35),
        ]
    }

    private static func speedUpperBlocks() -> [(HybridBlockType, String, HybridItemSpec, Int)] {
        [
            (.sprint, "Sprint", HybridItemSpec(kind: .sprint, distanceM: 20, sprintReps: 3, sprintSets: 2, intensityPct: 90, startType: .blocks, footwear: .spikes, restSec: 180), 20),
            (.lift, "Lift", HybridItemSpec(kind: .lift, exerciseName: "Bench press", sets: 4, repsMin: 5, repsMax: 5, loadLabel: "RPE 8"), 40),
        ]
    }

    private static func jumpsPullBlocks() -> [(HybridBlockType, String, HybridItemSpec, Int)] {
        [
            (.jumps, "Jumps", HybridItemSpec(kind: .jumps, jumpEvent: .longJump, jumpAttempts: 6, jumpApproachStrides: 12), 25),
            (.lift, "Lift", HybridItemSpec(kind: .lift, exerciseName: "Weighted pull-up", sets: 4, repsMin: 5, repsMax: 8, loadLabel: "+ load"), 35),
        ]
    }

    private static func hurdleBlocks() -> [(HybridBlockType, String, HybridItemSpec, Int)] {
        [
            (.hurdles, "Hurdles", HybridItemSpec(
                kind: .hurdles,
                hurdleCount: 5,
                hurdleHeightIn: 39,
                hurdleSpacingM: 8.5,
                approachStrides: 8,
                hurdleReps: 4
            ), 30),
            (.sprint, "Sprint", HybridItemSpec(kind: .sprint, distanceM: 30, sprintReps: 3, sprintSets: 1, intensityPct: 92, startType: .fly, footwear: .spikes, restSec: 300), 20),
        ]
    }

    private static func alignMealsToSession(_ session: TrainingSession, context: ModelContext) {
        let plan = PlatesDataStore.dayPlan(for: Date(), context: context)
        let meals = (try? context.fetch(FetchDescriptor<Meal>())) ?? []
        guard !meals.isEmpty else { return }

        func time(hour: Int, minute: Int) -> Date {
            var c = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            c.hour = hour
            c.minute = minute
            return Calendar.current.date(from: c) ?? Date()
        }

        let slots: [(MealSlotRole, String, Int, Int, String)] = [
            (.breakfast, "BREAKFAST", 8, 0, "Oats & berries bowl"),
            (.preSession, "PRE-SESSION", 10, 45, "Banana & honey"),
            (.postSession, "POST-SESSION", 14, 0, "Chicken & rice"),
            (.snack, "SNACK", 16, 30, "Greek yogurt parfait"),
            (.dinner, "DINNER", 19, 30, "Salmon & quinoa"),
        ]

        for existing in plan.plannedMeals {
            context.delete(existing)
        }

        for slot in slots {
            let meal = meals.first { $0.name.localizedCaseInsensitiveContains(slot.4.split(separator: " ").first.map(String.init) ?? "") }
                ?? meals.first!
            let planned = PlannedMeal(
                meal: meal,
                servings: 1,
                slotLabel: slot.1,
                slotRole: slot.0,
                slotTime: time(hour: slot.2, minute: slot.3),
                linkedSessionId: session.id,
                isEaten: slot.0 == .breakfast || slot.0 == .preSession
            )
            planned.dayPlan = plan
            context.insert(planned)
        }
    }
}
