import Foundation
import SwiftData

enum SeedDataService {
    private struct ExerciseSeed: Decodable {
        let name: String
        let primaryMuscle: String
        let secondaryMuscles: [String]
        let equipment: String
        let isLowerBody: Bool
    }

    private struct FoodSeed: Decodable {
        let name: String
        let brand: String?
        let servingName: String
        let servingGrams: Double
        let kcal: Double
        let protein: Double
        let carbs: Double
        let fat: Double
        let aisle: String
        let isVerified: Bool
    }

    @MainActor
    static func importIfNeeded(context: ModelContext) {
        let exerciseCount = (try? context.fetchCount(FetchDescriptor<Exercise>())) ?? 0
        if exerciseCount == 0 {
            importExercises(context: context)
        }
        let foodCount = (try? context.fetchCount(FetchDescriptor<Food>())) ?? 0
        if foodCount == 0 {
            importFoods(context: context)
        }
        ensureSampleProfile(context: context)
        ensureSampleRoutine(context: context)
        ensureWeekSchedules(context: context)
        ensureSampleMeals(context: context)
        ensureTodayPlan(context: context)
        ExerciseMetadataService.applyMovementPatterns(context: context)
        ExerciseMetadataService.ensureRunningExercises(context: context)
        ExerciseMetadataService.applyMovementPatterns(context: context)
        ExerciseMetadataService.ensureVariationGroups(context: context)
        ensureDemoTuesdayPull(context: context)
        ensureRichTodayPlan(context: context)
        HybridSeedService.importIfNeeded(context: context)
        if let profile = try? context.fetch(FetchDescriptor<UserProfile>()).first,
           profile.trainingModalities.isEmpty {
            profile.trainingModalitiesRaw = [
                TrainingModality.sprintsHurdles.rawValue,
                TrainingModality.jumps.rawValue,
                TrainingModality.lifting.rawValue,
            ]
        }
    }

    private static func importExercises(context: ModelContext) {
        guard let data = loadSeedJSON(named: "exercises"),
              let seeds = try? JSONDecoder().decode([ExerciseSeed].self, from: data)
        else { return }

        for seed in seeds {
            let muscle = MuscleGroup(rawValue: seed.primaryMuscle) ?? .core
            let secondary = seed.secondaryMuscles.compactMap { MuscleGroup(rawValue: $0) }
            let equipment = Equipment(rawValue: seed.equipment) ?? .bodyweight
            context.insert(
                Exercise(
                    name: seed.name,
                    primaryMuscle: muscle,
                    secondaryMuscles: secondary,
                    equipment: equipment,
                    isLowerBody: seed.isLowerBody
                )
            )
        }
    }

    private static func importFoods(context: ModelContext) {
        guard let data = loadSeedJSON(named: "foods"),
              let seeds = try? JSONDecoder().decode([FoodSeed].self, from: data)
        else { return }

        for seed in seeds {
            context.insert(
                Food(
                    name: seed.name,
                    brand: seed.brand,
                    servingName: seed.servingName,
                    servingGrams: seed.servingGrams,
                    kcal: seed.kcal,
                    protein: seed.protein,
                    carbs: seed.carbs,
                    fat: seed.fat,
                    source: .seed,
                    isVerified: seed.isVerified,
                    aisle: GroceryAisle(rawValue: seed.aisle) ?? .other
                )
            )
        }
    }

    private static func loadSeedJSON(named name: String) -> Data? {
        if let url = Bundle.main.url(forResource: name, withExtension: "json", subdirectory: "SeedData"),
           let data = try? Data(contentsOf: url) {
            return data
        }
        if let url = Bundle.main.url(forResource: name, withExtension: "json"),
           let data = try? Data(contentsOf: url) {
            return data
        }
        return nil
    }

    private static func ensureSampleProfile(context: ModelContext) {
        let count = (try? context.fetchCount(FetchDescriptor<UserProfile>())) ?? 0
        guard count == 0 else { return }
        context.insert(
            UserProfile(
                name: "Max",
                goals: [.buildMuscle, .feelHealthier],
                trainingDaysPerWeek: 4,
                onboardingComplete: false
            )
        )
    }

    private static func ensureSampleRoutine(context: ModelContext) {
        let count = (try? context.fetchCount(FetchDescriptor<Routine>())) ?? 0
        guard count == 0 else { return }

        let exercises = (try? context.fetch(FetchDescriptor<Exercise>())) ?? []
        let pullExercises = exercises.filter { $0.primaryMuscle == .back || $0.name.contains("Row") }.prefix(3)
        let routine = Routine(
            name: "Pull day",
            shortLabel: "Pull",
            stickerColor: .wine,
            dayType: .heavy,
            scheduledWeekdays: [2, 3, 4, 6]
        )
        context.insert(routine)

        for (index, exercise) in pullExercises.enumerated() {
            let item = RoutineItem(
                exercise: exercise,
                order: index,
                sets: 4,
                repMin: 5,
                repMax: 8,
                restSeconds: 120
            )
            item.routine = routine
            context.insert(item)
        }

        let push = Routine(
            name: "Push day",
            shortLabel: "Push",
            stickerColor: .olive,
            dayType: .standard,
            scheduledWeekdays: [1, 3, 5],
            sortOrder: 1
        )
        context.insert(push)
        let pushEx = exercises.filter { $0.primaryMuscle == .chest }.prefix(3)
        for (index, exercise) in pushEx.enumerated() {
            let item = RoutineItem(exercise: exercise, order: index, sets: 3, repMin: 8, repMax: 12, restSeconds: 90)
            item.routine = push
            context.insert(item)
        }
    }

    private static func ensureWeekSchedules(context: ModelContext) {
        let count = (try? context.fetchCount(FetchDescriptor<WeekSchedule>())) ?? 0
        guard count == 0 else { return }
        let routines = (try? context.fetch(FetchDescriptor<Routine>())) ?? []
        for routine in routines {
            for day in routine.scheduledWeekdays {
                context.insert(WeekSchedule(weekday: day, routine: routine, isRest: false))
            }
        }
    }

    private static func ensureSampleMeals(context: ModelContext) {
        let count = (try? context.fetchCount(FetchDescriptor<Meal>())) ?? 0
        guard count == 0 else { return }
        let foods = (try? context.fetch(FetchDescriptor<Food>())) ?? []
        guard let chicken = foods.first(where: { $0.name.contains("Chicken") }),
              let rice = foods.first(where: { $0.name.contains("rice") })
        else { return }

        let meal = Meal(name: "Post-workout bowl", timingTags: [.post, .lunch], isFavorite: true)
        context.insert(meal)
        let i1 = MealIngredient(food: chicken, servings: 1)
        i1.meal = meal
        let i2 = MealIngredient(food: rice, servings: 1)
        i2.meal = meal
        context.insert(i1)
        context.insert(i2)

        let breakfast = Meal(name: "Greek yogurt & berries", timingTags: [.breakfast], isFavorite: true)
        context.insert(breakfast)
        if let yogurt = foods.first(where: { $0.name.contains("Greek") }),
           let berries = foods.first(where: { $0.name.contains("Blue") }) {
            let b1 = MealIngredient(food: yogurt, servings: 1)
            b1.meal = breakfast
            let b2 = MealIngredient(food: berries, servings: 0.5)
            b2.meal = breakfast
            context.insert(b1)
            context.insert(b2)
        }
    }

    private static func ensureTodayPlan(context: ModelContext) {
        let start = Calendar.current.startOfDay(for: Date())
        let existing = (try? context.fetch(FetchDescriptor<DayPlan>())) ?? []
        guard !existing.contains(where: { Calendar.current.isDate($0.date, inSameDayAs: start) }) else { return }

        let plan = DayPlan(date: start)
        context.insert(plan)
        let meals = (try? context.fetch(FetchDescriptor<Meal>())) ?? []
        guard let breakfast = meals.first(where: { $0.name.contains("yogurt") }),
              let post = meals.first(where: { $0.name.contains("Post") })
        else { return }

        let slots: [(Meal, String, Int, Int)] = [
            (breakfast, "Breakfast", 8, 0),
            (post, "Post-workout", 13, 30),
        ]
        for (meal, label, hour, minute) in slots {
            var comps = Calendar.current.dateComponents([.year, .month, .day], from: start)
            comps.hour = hour
            comps.minute = minute
            let when = Calendar.current.date(from: comps)
            let planned = PlannedMeal(meal: meal, servings: 1, slotLabel: label, slotTime: when)
            planned.dayPlan = plan
            context.insert(planned)
        }

        context.insert(BodyWeightEntry(date: start, weightKg: 79, source: .manual))
    }

    /// Ensures Tuesday (weekday 3) has pull day for demo — e.g. Nov 3, 2026.
    private static func ensureDemoTuesdayPull(context: ModelContext) {
        let routines = (try? context.fetch(FetchDescriptor<Routine>())) ?? []
        guard let pull = routines.first(where: { $0.shortLabel == "Pull" || $0.name.localizedCaseInsensitiveContains("pull") }) else { return }
        if !pull.scheduledWeekdays.contains(3) {
            pull.scheduledWeekdays.append(3)
        }
        let schedules = (try? context.fetch(FetchDescriptor<WeekSchedule>())) ?? []
        if !schedules.contains(where: { $0.weekday == 3 && $0.routine?.id == pull.id }) {
            context.insert(WeekSchedule(weekday: 3, routine: pull))
        }
    }

    /// Fills today with planned demo meals if the day is sparse (for UI preview).
    @MainActor
    private static func ensureRichTodayPlan(context: ModelContext) {
        let start = Calendar.current.startOfDay(for: Date())
        let dayKey = "richPlan-\(start.timeIntervalSince1970)"
        guard !UserDefaults.standard.bool(forKey: dayKey) else { return }

        let plan = PlatesDataStore.dayPlan(for: start, context: context)
        guard plan.plannedMeals.count < 4 else { return }
        UserDefaults.standard.set(true, forKey: dayKey)

        for preset in PresetMealLibrary.all.prefix(5) {
            let food = Food(
                name: preset.name,
                servingName: "1 meal",
                servingGrams: 100,
                kcal: Double(preset.kcal),
                protein: Double(preset.protein),
                carbs: Double(preset.carbs),
                fat: Double(preset.fat),
                source: .user
            )
            context.insert(food)
            let meal = Meal(name: preset.name, timingTags: preset.timing, isFavorite: preset.isFavorite)
            context.insert(meal)
            let ing = MealIngredient(food: food, servings: 1)
            ing.meal = meal
            context.insert(ing)

            let hour: Int
            switch preset.timing.first {
            case .breakfast: hour = 8
            case .pre: hour = 11
            case .post: hour = 14
            case .lunch: hour = 12
            case .dinner: hour = 19
            default: hour = 15
            }
            var comps = Calendar.current.dateComponents([.year, .month, .day], from: start)
            comps.hour = hour
            comps.minute = 0
            let when = Calendar.current.date(from: comps)
            let label = preset.timing.first?.rawValue.capitalized ?? "Meal"
            let planned = PlannedMeal(meal: meal, servings: 1, slotLabel: label, slotTime: when, isEaten: false)
            planned.dayPlan = plan
            context.insert(planned)
        }
    }
}
