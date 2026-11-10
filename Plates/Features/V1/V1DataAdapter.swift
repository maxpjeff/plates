import Foundation
import SwiftData

@MainActor
enum V1DataAdapter {
    static func today(context: ModelContext, date: Date) -> TodayScreenModel {
        let targets = PlatesDataStore.targets(for: date, context: context)
        let eaten = PlatesDataStore.macroTotals(for: date, context: context)
        let left = max(0, targets.kcal - Int(eaten.kcal.rounded()))
        let progress = targets.kcal > 0 ? eaten.kcal / Double(targets.kcal) : 0
        let load = HybridDataStore.dayLoad(for: date, context: context)?.label ?? .rest
        let session = HybridDataStore.session(for: date, context: context)
        let time = session?.plannedStart?.formatted(date: .omitted, time: .shortened) ?? ""
        let subtitle = "\(session?.title ?? "Rest")\(time.isEmpty ? "" : " · \(time)")"
        let plan = PlatesDataStore.dayPlan(for: date, context: context)
        let timeline = buildTimeline(context: context, date: date, plan: plan, session: session)

        return TodayScreenModel(
            overline: date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()),
            profileInitials: String(PlatesDataStore.profile(context: context).name.prefix(1)).uppercased(),
            dayStrip: dayStrip(around: date, context: context, selected: date),
            load: load,
            sessionSubtitle: subtitle,
            kcalLeft: left,
            kcalEaten: Int(eaten.kcal.rounded()),
            kcalTarget: targets.kcal,
            calorieProgress: progress,
            proteinEaten: Int(eaten.protein.rounded()),
            proteinTarget: targets.proteinG,
            proteinPercent: pct(eaten.protein, targets.proteinG),
            carbsEaten: Int(eaten.carbs.rounded()),
            carbsTarget: targets.carbsG,
            carbsPercent: pct(eaten.carbs, targets.carbsG),
            fatEaten: Int(eaten.fat.rounded()),
            fatTarget: targets.fatG,
            fatPercent: pct(eaten.fat, targets.fatG),
            mealsCount: plan.plannedMeals.count,
            sessionsCount: session == nil ? 0 : 1,
            timeline: timeline
        )
    }

    static func fuel(context: ModelContext, date: Date) -> FuelScreenModel {
        let profile = PlatesDataStore.profile(context: context)
        let targets = PlatesDataStore.targets(for: date, context: context)
        let eaten = PlatesDataStore.macroTotals(for: date, context: context)
        let planned = PlatesDataStore.plannedMacroTotals(for: date, context: context)
        let leftKcal = max(0, targets.kcal - Int(eaten.kcal.rounded()))
        let progress = targets.kcal > 0 ? eaten.kcal / Double(targets.kcal) : 0
        let breakdown = PlatesDataStore.fuelBreakdown(for: date, context: context)
        let load = HybridDataStore.dayLoad(for: date, context: context)?.label ?? .rest
        let plan = PlatesDataStore.dayPlan(for: date, context: context)
        let foods = plan.plannedMeals.sorted { ($0.slotTime ?? .distantFuture) < ($1.slotTime ?? .distantFuture) }.map { foodRow($0) }
        let eatenCount = plan.plannedMeals.filter(\.isEaten).count
        let gap = PlatesDataStore.fuelGap(for: date, context: context)

        return FuelScreenModel(
            overline: goalOverline(profile),
            dayStrip: dayStrip(around: date, context: context, selected: date),
            load: load,
            kcalEaten: Int(eaten.kcal.rounded()),
            kcalTarget: targets.kcal,
            calorieProgress: progress,
            kcalLeft: leftKcal,
            fuelBreakdown: "Base \(PlatesFormat.grouped(breakdown.baseKcal)) + \(breakdown.sessionBonus) for today's session",
            proteinEaten: Int(eaten.protein.rounded()),
            proteinTarget: targets.proteinG,
            proteinLeft: max(0, targets.proteinG - Int(eaten.protein.rounded())),
            proteinPercent: pct(eaten.protein, targets.proteinG),
            carbsEaten: Int(eaten.carbs.rounded()),
            carbsTarget: targets.carbsG,
            carbsLeft: max(0, targets.carbsG - Int(eaten.carbs.rounded())),
            carbsPercent: pct(eaten.carbs, targets.carbsG),
            fatEaten: Int(eaten.fat.rounded()),
            fatTarget: targets.fatG,
            fatLeft: max(0, targets.fatG - Int(eaten.fat.rounded())),
            fatPercent: pct(eaten.fat, targets.fatG),
            gapTitle: gap.map { "Plan is \($0.gap) kcal short" } ?? MockData.fuelModel.gapTitle,
            gapBody: gap != nil ? MockData.fuelModel.gapBody : "",
            foods: foods.isEmpty ? MockData.fuelModel.foods : foods,
            eatenCount: eatenCount,
            plannedCount: max(0, plan.plannedMeals.count - eatenCount)
        )
    }

    static func plan(context: ModelContext, weekContaining date: Date = Date()) -> PlanScreenModel {
        let days = weekDates(containing: date)
        let dayModels: [PlanDayModel] = days.map { day in
            let load = HybridDataStore.dayLoad(for: day, context: context)?.label ?? .rest
            let targets = PlatesDataStore.targets(for: day, context: context)
            let session = HybridDataStore.session(for: day, context: context)
            let title = session?.title ?? (load == .rest ? "Rest day" : "Training")
            let isToday = Calendar.current.isDateInToday(day)
            let weekday = isToday ? "Today" : day.formatted(.dateTime.weekday(.abbreviated))
            let dayNum = Calendar.current.component(.day, from: day)
            return PlanDayModel(
                date: day,
                day: dayNum,
                weekdayLabel: weekday,
                isToday: isToday,
                load: load,
                title: title,
                chips: sessionChips(session),
                kcal: targets.kcal,
                barHeight: barHeight(for: load)
            )
        }
        let chart = dayModels.enumerated().map { index, day in
            LoadChartDay(
                letter: chartLetter(for: days[index]),
                load: day.load,
                barHeight: day.barHeight,
                isToday: day.isToday
            )
        }
        let interval = Calendar.current.dateInterval(of: .weekOfYear, for: date)!
        let end = Calendar.current.date(byAdding: .day, value: -1, to: interval.end)!
        let overline = "\(interval.start.formatted(.dateTime.month().day())) – \(end.formatted(.dateTime.month().day()))"
        let counts = loadCounts(dayModels)

        return PlanScreenModel(
            overline: overline,
            loadSummary: "\(counts.high) high · \(counts.modLow) moderate-low · \(counts.rest) rest",
            chartDays: chart,
            days: dayModels
        )
    }

    static func liveSession(from session: TrainingSession?) -> LiveSessionModel {
        let base = MockData.liveSessionModel
        guard let session else { return base }
        let blockLabel = session.blocks.sorted { $0.order < $1.order }.first?.blockType.label ?? "Sprint"
        return LiveSessionModel(
            elapsed: base.elapsed,
            title: session.title,
            blockProgress: "Block 1 of \(max(1, session.blocks.count)) · \(blockLabel)",
            segmentFill: base.segmentFill,
            exerciseTitle: base.exerciseTitle,
            exerciseSubtitle: base.exerciseSubtitle,
            restLabel: base.restLabel,
            reps: base.reps,
            timingPills: base.timingPills,
            selectedTiming: base.selectedTiming,
            wind: base.wind
        )
    }

    // MARK: - Helpers

    private static func pct(_ eaten: Double, _ target: Int) -> Double {
        guard target > 0 else { return 0 }
        return min(1, eaten / Double(target))
    }

    private static func goalOverline(_ profile: UserProfile) -> String {
        if profile.goals.contains(.buildMuscle) { return "Goal · Lean gain" }
        if profile.goals.contains(.loseFat) { return "Goal · Fat loss" }
        return "Goal · Maintain"
    }

    private static func dayStrip(around date: Date, context: ModelContext, selected: Date) -> [DayStripModel] {
        weekDates(containing: date).map { day in
            let load = HybridDataStore.dayLoad(for: day, context: context)?.label ?? .rest
            let num = Calendar.current.component(.day, from: day)
            return DayStripModel(
                weekday: day.formatted(.dateTime.weekday(.abbreviated)),
                dateNumber: num,
                load: load,
                isSelected: Calendar.current.isDate(day, inSameDayAs: selected)
            )
        }
    }

    private static func weekDates(containing date: Date) -> [Date] {
        guard let interval = Calendar.current.dateInterval(of: .weekOfYear, for: date) else { return [] }
        return (0..<7).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: interval.start) }
    }

    private static func chartLetter(for date: Date) -> String {
        let weekday = Calendar.current.component(.weekday, from: date)
        return ["S", "M", "T", "W", "T", "F", "S"][weekday - 1]
    }

    private static func barHeight(for load: DayLoadLabel) -> CGFloat {
        switch load {
        case .high: 112
        case .moderate: 74
        case .low: 40
        case .rest: 18
        }
    }

    private static func loadCounts(_ days: [PlanDayModel]) -> (high: Int, modLow: Int, rest: Int) {
        var high = 0, modLow = 0, rest = 0
        for day in days {
            switch day.load {
            case .high: high += 1
            case .moderate, .low: modLow += 1
            case .rest: rest += 1
            }
        }
        return (high, modLow, rest)
    }

    private static func sessionChips(_ session: TrainingSession?) -> [PlanChipStyle] {
        guard let session else { return [.standard("Walk + mobility")] }
        return session.blocks.sorted { $0.order < $1.order }.map { .standard($0.blockType.label) }
    }

    private static func buildTimeline(
        context: ModelContext,
        date: Date,
        plan: DayPlan,
        session: TrainingSession?
    ) -> [TodayTimelineItem] {
        var items: [(Date, TodayTimelineItem)] = []
        for meal in plan.plannedMeals {
            let m = PlatesDataStore.mealMacros(meal)
            let time = meal.slotTime?.formatted(date: .omitted, time: .shortened) ?? "—"
            items.append((meal.slotTime ?? .distantFuture, .meal(MealTimelineModel(
                time: time,
                role: meal.slotLabel,
                name: meal.meal?.name ?? meal.food?.name ?? "Meal",
                kcal: Int(m.kcal.rounded()),
                protein: Int(m.protein.rounded()),
                carbs: Int(m.carbs.rounded()),
                fat: Int(m.fat.rounded()),
                eaten: meal.isEaten
            ))))
        }
        if let session {
            let blocks = session.blocks.sorted { $0.order < $1.order }.compactMap { block -> SessionBlockRow? in
                guard let spec = block.items.first?.plannedSpec else { return nil }
                return SessionBlockRow(
                    icon: blockIcon(block.blockType),
                    name: block.blockType.label,
                    detail: blockDetail(block.blockType, spec: spec)
                )
            }
            let mins = session.blocks.map(\.estimatedMinutes).reduce(0, +)
            items.append((session.plannedStart ?? .distantFuture, .session(SessionTimelineModel(
                time: session.plannedStart?.formatted(date: .omitted, time: .shortened) ?? "—",
                caps: "SESSION · \(session.blocks.count) BLOCKS · ~\(mins) MIN",
                title: session.title,
                blocks: blocks.isEmpty ? fallbackSessionBlocks : blocks,
                before: nil,
                after: nil
            ))))
        }
        return items.sorted { $0.0 < $1.0 }.map(\.1)
    }

    private static func foodRow(_ planned: PlannedMeal) -> FoodRowModel {
        let m = PlatesDataStore.mealMacros(planned)
        return FoodRowModel(
            name: planned.meal?.name ?? planned.food?.name ?? "Food",
            icon: "fork.knife",
            protein: Int(m.protein.rounded()),
            carbs: Int(m.carbs.rounded()),
            fat: Int(m.fat.rounded()),
            kcal: Int(m.kcal.rounded()),
            time: planned.slotTime?.formatted(date: .omitted, time: .shortened) ?? "—",
            planned: !planned.isEaten
        )
    }

    private static var fallbackSessionBlocks: [SessionBlockRow] {
        for item in MockData.todayModel.timeline {
            if case .session(let s) = item { return s.blocks }
        }
        return []
    }

    private static func blockIcon(_ type: HybridBlockType) -> String {
        switch type {
        case .sprint: "bolt"
        case .plyo: "arrow.up"
        case .lift: "dumbbell"
        default: "circle.fill"
        }
    }

    private static func blockDetail(_ type: HybridBlockType, spec: HybridItemSpec) -> String {
        switch type {
        case .sprint:
            return "\(spec.sprintReps ?? 4) × \(Int(spec.distanceM ?? 30)) m fly @ \(spec.intensityPct ?? 95)% · \((spec.restSec ?? 240) / 60) min rest"
        case .plyo:
            return "\(spec.plyoDrill ?? "Pogos + bounds") · \((spec.contactsPerSet ?? 30) * (spec.plyoSets ?? 2)) contacts"
        case .lift:
            return "\(spec.exerciseName ?? "Lift") \(spec.sets ?? 4) × \(spec.repsMin ?? 3)"
        default: return type.label
        }
    }
}
