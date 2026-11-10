import Foundation
import SwiftData

@Model
final class UserProfile {
    @Attribute(.unique) var id: UUID
    var name: String
    var sexRaw: String
    var birthDate: Date
    var heightCm: Double
    var goalsRaw: [String]
    var liftExperienceRaw: String
    var foodDetailRaw: String
    var trainingDetailRaw: String
    var trainingDaysPerWeek: Int
    var unitsRaw: String
    var proteinPerKg: Double
    /// Optional so SwiftData can migrate older stores; use `resolvedBodyWeightKg` in app code.
    var bodyWeightKg: Double?
    var createdAt: Date
    var onboardingComplete: Bool
    var trainingModalitiesRaw: [String]?

    init(
        id: UUID = UUID(),
        name: String = "",
        sex: Sex = .preferNotToSay,
        birthDate: Date = Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date(),
        heightCm: Double = 175,
        goals: [Goal] = [],
        liftExperience: LiftExperience = .new,
        foodDetail: DetailLevel = .balanced,
        trainingDetail: DetailLevel = .balanced,
        trainingDaysPerWeek: Int = 4,
        units: WeightUnit = .lb,
        proteinPerKg: Double = 1.6,
        bodyWeightKg: Double = 79,
        createdAt: Date = Date(),
        onboardingComplete: Bool = false
    ) {
        self.id = id
        self.name = name
        self.sexRaw = sex.rawValue
        self.birthDate = birthDate
        self.heightCm = heightCm
        self.goalsRaw = goals.map(\.rawValue)
        self.liftExperienceRaw = liftExperience.rawValue
        self.foodDetailRaw = foodDetail.rawValue
        self.trainingDetailRaw = trainingDetail.rawValue
        self.trainingDaysPerWeek = trainingDaysPerWeek
        self.unitsRaw = units.rawValue
        self.proteinPerKg = proteinPerKg
        self.bodyWeightKg = bodyWeightKg
        self.createdAt = createdAt
        self.onboardingComplete = onboardingComplete
        self.trainingModalitiesRaw = nil
    }

    var trainingModalities: [TrainingModality] {
        (trainingModalitiesRaw ?? []).compactMap(TrainingModality.init(rawValue:))
    }

    var sex: Sex { Sex(rawValue: sexRaw) ?? .preferNotToSay }
    var goals: [Goal] { goalsRaw.compactMap(Goal.init(rawValue:)) }
    var foodDetail: DetailLevel { DetailLevel(rawValue: foodDetailRaw) ?? .balanced }
    var trainingDetail: DetailLevel { DetailLevel(rawValue: trainingDetailRaw) ?? .balanced }
    var units: WeightUnit { WeightUnit(rawValue: unitsRaw) ?? .lb }
    var resolvedBodyWeightKg: Double { bodyWeightKg ?? 79 }
}

@Model
final class Exercise {
    @Attribute(.unique) var id: UUID
    var name: String
    var primaryMuscleRaw: String
    var secondaryMusclesRaw: [String]
    var equipmentRaw: String
    var movementPatternsRaw: [String]?
    var isCustom: Bool
    var isLowerBody: Bool

    init(
        id: UUID = UUID(),
        name: String,
        primaryMuscle: MuscleGroup,
        secondaryMuscles: [MuscleGroup] = [],
        equipment: Equipment,
        movementPatterns: [MovementPattern] = [],
        isCustom: Bool = false,
        isLowerBody: Bool = false
    ) {
        self.id = id
        self.name = name
        self.primaryMuscleRaw = primaryMuscle.rawValue
        self.secondaryMusclesRaw = secondaryMuscles.map(\.rawValue)
        self.equipmentRaw = equipment.rawValue
        self.movementPatternsRaw = movementPatterns.isEmpty ? nil : movementPatterns.map(\.rawValue)
        self.isCustom = isCustom
        self.isLowerBody = isLowerBody
    }

    var primaryMuscle: MuscleGroup { MuscleGroup(rawValue: primaryMuscleRaw) ?? .core }
    var secondaryMuscles: [MuscleGroup] {
        secondaryMusclesRaw.compactMap { MuscleGroup(rawValue: $0) }
    }
    var equipment: Equipment { Equipment(rawValue: equipmentRaw) ?? .bodyweight }
    var movementPatterns: [MovementPattern] {
        (movementPatternsRaw ?? []).compactMap(MovementPattern.init(rawValue:))
    }

    var movementPatternLabel: String {
        let patterns = movementPatterns.map(\.label)
        if !patterns.isEmpty { return patterns.joined(separator: " · ") }
        return primaryMuscle.rawValue.capitalized
    }
}

@Model
final class ExerciseVariationGroup {
    @Attribute(.unique) var id: UUID
    var name: String
    @Relationship var exercises: [Exercise]

    init(id: UUID = UUID(), name: String, exercises: [Exercise] = []) {
        self.id = id
        self.name = name
        self.exercises = exercises
    }
}

@Model
final class Routine {
    @Attribute(.unique) var id: UUID
    var name: String
    var shortLabel: String
    var stickerColorRaw: String
    var dayTypeRaw: String
    var scheduledWeekdays: [Int]
    var sortOrder: Int
    @Relationship(deleteRule: .cascade, inverse: \RoutineItem.routine)
    var items: [RoutineItem]

    init(
        id: UUID = UUID(),
        name: String,
        shortLabel: String,
        stickerColor: StickerColorName = .wine,
        dayType: DayType = .standard,
        scheduledWeekdays: [Int] = [],
        sortOrder: Int = 0,
        items: [RoutineItem] = []
    ) {
        self.id = id
        self.name = name
        self.shortLabel = shortLabel
        self.stickerColorRaw = stickerColor.rawValue
        self.dayTypeRaw = dayType.rawValue
        self.scheduledWeekdays = scheduledWeekdays
        self.sortOrder = sortOrder
        self.items = items
    }

    var stickerColor: StickerColorName { StickerColorName(rawValue: stickerColorRaw) ?? .wine }
    var dayType: DayType { DayType(rawValue: dayTypeRaw) ?? .standard }
}

@Model
final class RoutineItem {
    @Attribute(.unique) var id: UUID
    var order: Int
    var sets: Int
    var repMin: Int
    var repMax: Int
    var restSeconds: Int
    var autoProgression: Bool
    var exercise: Exercise?
    var variationGroup: ExerciseVariationGroup?
    var routine: Routine?

    init(
        id: UUID = UUID(),
        exercise: Exercise? = nil,
        variationGroup: ExerciseVariationGroup? = nil,
        order: Int = 0,
        sets: Int = 3,
        repMin: Int = 8,
        repMax: Int = 12,
        restSeconds: Int = 90,
        autoProgression: Bool = true
    ) {
        self.id = id
        self.exercise = exercise
        self.variationGroup = variationGroup
        self.order = order
        self.sets = sets
        self.repMin = repMin
        self.repMax = repMax
        self.restSeconds = restSeconds
        self.autoProgression = autoProgression
    }

    var displayTitle: String {
        variationGroup?.name ?? exercise?.name ?? "Exercise"
    }
}

@Model
final class Program {
    @Attribute(.unique) var id: UUID
    var name: String
    var startDate: Date
    var lengthWeeks: Int
    var deloadWeek: Int?
    @Relationship var routines: [Routine]

    init(
        id: UUID = UUID(),
        name: String,
        startDate: Date = Date(),
        lengthWeeks: Int = 6,
        deloadWeek: Int? = nil,
        routines: [Routine] = []
    ) {
        self.id = id
        self.name = name
        self.startDate = startDate
        self.lengthWeeks = lengthWeeks
        self.deloadWeek = deloadWeek
        self.routines = routines
    }
}

@Model
final class WeekSchedule {
    @Attribute(.unique) var id: UUID
    var weekday: Int
    var cardioName: String?
    var cardioMinutes: Int?
    var isRest: Bool
    var preferredWorkoutTime: Date?
    var routine: Routine?
    var dayLoadLabelRaw: String?
    var sessionTitle: String?
    @Relationship var trainingSession: TrainingSession?

    init(
        id: UUID = UUID(),
        weekday: Int,
        routine: Routine? = nil,
        trainingSession: TrainingSession? = nil,
        cardioName: String? = nil,
        cardioMinutes: Int? = nil,
        isRest: Bool = false,
        preferredWorkoutTime: Date? = nil,
        dayLoadLabelRaw: String? = nil,
        sessionTitle: String? = nil
    ) {
        self.id = id
        self.weekday = weekday
        self.routine = routine
        self.trainingSession = trainingSession
        self.cardioName = cardioName
        self.cardioMinutes = cardioMinutes
        self.isRest = isRest
        self.preferredWorkoutTime = preferredWorkoutTime
        self.dayLoadLabelRaw = dayLoadLabelRaw
        self.sessionTitle = sessionTitle
    }

    var dayLoadLabel: DayLoadLabel? {
        guard let dayLoadLabelRaw else { return nil }
        return DayLoadLabel(rawValue: dayLoadLabelRaw)
    }
}

@Model
final class WorkoutSession {
    @Attribute(.unique) var id: UUID
    var date: Date
    var startedAt: Date?
    var endedAt: Date?
    var notes: String
    var healthKitWorkoutID: String?
    var routine: Routine?
    @Relationship(deleteRule: .cascade, inverse: \SetLog.session)
    var sets: [SetLog]

    init(
        id: UUID = UUID(),
        routine: Routine? = nil,
        date: Date = Date(),
        startedAt: Date? = nil,
        endedAt: Date? = nil,
        notes: String = "",
        healthKitWorkoutID: String? = nil,
        sets: [SetLog] = []
    ) {
        self.id = id
        self.routine = routine
        self.date = date
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.notes = notes
        self.healthKitWorkoutID = healthKitWorkoutID
        self.sets = sets
    }
}

@Model
final class SetLog {
    @Attribute(.unique) var id: UUID
    var setIndex: Int
    var weightKg: Double
    var reps: Int
    var rir: Int?
    var isWarmup: Bool
    var completedAt: Date?
    var isPR: Bool
    var exercise: Exercise?
    var session: WorkoutSession?

    init(
        id: UUID = UUID(),
        exercise: Exercise? = nil,
        setIndex: Int = 0,
        weightKg: Double = 0,
        reps: Int = 0,
        rir: Int? = nil,
        isWarmup: Bool = false,
        completedAt: Date? = nil,
        isPR: Bool = false
    ) {
        self.id = id
        self.exercise = exercise
        self.setIndex = setIndex
        self.weightKg = weightKg
        self.reps = reps
        self.rir = rir
        self.isWarmup = isWarmup
        self.completedAt = completedAt
        self.isPR = isPR
    }
}

@Model
final class Food {
    @Attribute(.unique) var id: UUID
    var name: String
    var brand: String?
    var servingName: String
    var servingGrams: Double
    var kcal: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var fiber: Double?
    var sourceRaw: String
    var barcode: String?
    var isVerified: Bool
    var aisleRaw: String

    init(
        id: UUID = UUID(),
        name: String,
        brand: String? = nil,
        servingName: String = "1 serving",
        servingGrams: Double = 100,
        kcal: Double,
        protein: Double,
        carbs: Double,
        fat: Double,
        fiber: Double? = nil,
        source: FoodSource = .seed,
        barcode: String? = nil,
        isVerified: Bool = false,
        aisle: GroceryAisle = .other
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.servingName = servingName
        self.servingGrams = servingGrams
        self.kcal = kcal
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.fiber = fiber
        self.sourceRaw = source.rawValue
        self.barcode = barcode
        self.isVerified = isVerified
        self.aisleRaw = aisle.rawValue
    }

    var source: FoodSource { FoodSource(rawValue: sourceRaw) ?? .seed }
    var aisle: GroceryAisle { GroceryAisle(rawValue: aisleRaw) ?? .other }
}

@Model
final class Meal {
    @Attribute(.unique) var id: UUID
    var name: String
    var timingTagsRaw: [String]
    var isFavorite: Bool
    @Attribute(.externalStorage) var photoData: Data?
    var stickerColorHex: String?
    @Relationship(deleteRule: .cascade, inverse: \MealIngredient.meal)
    var ingredients: [MealIngredient]

    init(
        id: UUID = UUID(),
        name: String,
        timingTags: [MealTimingTag] = [],
        isFavorite: Bool = false,
        photoData: Data? = nil,
        stickerColorHex: String? = nil,
        ingredients: [MealIngredient] = []
    ) {
        self.id = id
        self.name = name
        self.timingTagsRaw = timingTags.map(\.rawValue)
        self.isFavorite = isFavorite
        self.photoData = photoData
        self.stickerColorHex = stickerColorHex
        self.ingredients = ingredients
    }
}

@Model
final class MealIngredient {
    @Attribute(.unique) var id: UUID
    var servings: Double
    var food: Food?
    var meal: Meal?

    init(id: UUID = UUID(), food: Food? = nil, servings: Double = 1) {
        self.id = id
        self.food = food
        self.servings = servings
    }
}

@Model
final class DayPlan {
    @Attribute(.unique) var id: UUID
    var date: Date
    @Relationship(deleteRule: .cascade, inverse: \PlannedMeal.dayPlan)
    var plannedMeals: [PlannedMeal]

    init(id: UUID = UUID(), date: Date, plannedMeals: [PlannedMeal] = []) {
        self.id = id
        self.date = date
        self.plannedMeals = plannedMeals
    }
}

@Model
final class PlannedMeal {
    @Attribute(.unique) var id: UUID
    var slotLabel: String
    var slotTime: Date?
    var slotRoleRaw: String?
    var linkedSessionId: UUID?
    var servings: Double
    var isEaten: Bool
    var eatenAt: Date?
    var meal: Meal?
    var food: Food?
    var dayPlan: DayPlan?

    init(
        id: UUID = UUID(),
        meal: Meal? = nil,
        food: Food? = nil,
        servings: Double = 1,
        slotLabel: String = "Lunch",
        slotRole: MealSlotRole = .anytime,
        slotTime: Date? = nil,
        linkedSessionId: UUID? = nil,
        isEaten: Bool = false,
        eatenAt: Date? = nil
    ) {
        self.id = id
        self.meal = meal
        self.food = food
        self.servings = servings
        self.slotLabel = slotLabel
        self.slotRoleRaw = slotRole.rawValue
        self.slotTime = slotTime
        self.linkedSessionId = linkedSessionId
        self.isEaten = isEaten
        self.eatenAt = eatenAt
    }

    var slotRole: MealSlotRole {
        MealSlotRole(rawValue: slotRoleRaw ?? "") ?? .anytime
    }
}

@Model
final class TrainingSession {
    @Attribute(.unique) var id: UUID
    var dayDate: Date
    var title: String
    var plannedStart: Date?
    var sortOrder: Int
    var isTemplate: Bool
    var notes: String
    @Relationship(deleteRule: .cascade, inverse: \TrainingBlock.session)
    var blocks: [TrainingBlock]

    init(
        id: UUID = UUID(),
        dayDate: Date,
        title: String,
        plannedStart: Date? = nil,
        sortOrder: Int = 0,
        isTemplate: Bool = false,
        notes: String = "",
        blocks: [TrainingBlock] = []
    ) {
        self.id = id
        self.dayDate = dayDate
        self.title = title
        self.plannedStart = plannedStart
        self.sortOrder = sortOrder
        self.isTemplate = isTemplate
        self.notes = notes
        self.blocks = blocks
    }
}

@Model
final class TrainingBlock {
    @Attribute(.unique) var id: UUID
    var typeRaw: String
    var order: Int
    var title: String
    var notes: String
    var rpeTarget: Double?
    var rpeActual: Double?
    var completedAt: Date?
    var estimatedMinutes: Int
    var session: TrainingSession?
    @Relationship(deleteRule: .cascade, inverse: \TrainingBlockItem.block)
    var items: [TrainingBlockItem]

    init(
        id: UUID = UUID(),
        type: HybridBlockType,
        order: Int,
        title: String,
        notes: String = "",
        rpeTarget: Double? = nil,
        estimatedMinutes: Int = 20,
        items: [TrainingBlockItem] = []
    ) {
        self.id = id
        self.typeRaw = type.rawValue
        self.order = order
        self.title = title
        self.notes = notes
        self.rpeTarget = rpeTarget
        self.rpeActual = nil
        self.completedAt = nil
        self.estimatedMinutes = estimatedMinutes
        self.items = items
    }

    var blockType: HybridBlockType { HybridBlockType(rawValue: typeRaw) ?? .lift }
}

@Model
final class TrainingBlockItem {
    @Attribute(.unique) var id: UUID
    var order: Int
    var restSec: Int
    @Attribute(.externalStorage) var plannedData: Data?
    @Attribute(.externalStorage) var actualData: Data?
    var block: TrainingBlock?

    init(id: UUID = UUID(), order: Int = 0, restSec: Int = 90, planned: HybridItemSpec) {
        self.id = id
        self.order = order
        self.restSec = restSec
        self.plannedData = HybridSessionCodec.encodeSpec(planned)
        self.actualData = nil
    }

    var plannedSpec: HybridItemSpec? { HybridSessionCodec.decodeSpec(plannedData) }
    var actualResult: HybridItemResult? { HybridSessionCodec.decodeResult(actualData) }

    func updateActual(_ result: HybridItemResult) {
        actualData = HybridSessionCodec.encodeResult(result)
    }
}

@Model
final class TrackEvent {
    @Attribute(.unique) var id: UUID
    var name: String
    var code: String
    var unitRaw: String
    var sortOrder: Int

    init(id: UUID = UUID(), name: String, code: String, unit: PerformanceUnit, sortOrder: Int = 0) {
        self.id = id
        self.name = name
        self.code = code
        self.unitRaw = unit.rawValue
        self.sortOrder = sortOrder
    }

    var unit: PerformanceUnit { PerformanceUnit(rawValue: unitRaw) ?? .seconds }
}

@Model
final class PerformanceRecord {
    @Attribute(.unique) var id: UUID
    var value: Double
    var unitRaw: String
    var date: Date
    var contextRaw: String
    var timingRaw: String?
    var windMS: Double?
    var isWindLegal: Bool
    var meetName: String?
    var notes: String
    var event: TrackEvent?
    var exercise: Exercise?

    init(
        id: UUID = UUID(),
        value: Double,
        unit: PerformanceUnit,
        date: Date = Date(),
        context: PerformanceContext = .training,
        timing: TimingMethod? = nil,
        windMS: Double? = nil,
        isWindLegal: Bool = true,
        meetName: String? = nil,
        notes: String = "",
        event: TrackEvent? = nil,
        exercise: Exercise? = nil
    ) {
        self.id = id
        self.value = value
        self.unitRaw = unit.rawValue
        self.date = date
        self.contextRaw = context.rawValue
        self.timingRaw = timing?.rawValue
        self.windMS = windMS
        self.isWindLegal = isWindLegal
        self.meetName = meetName
        self.notes = notes
        self.event = event
        self.exercise = exercise
    }

    var unit: PerformanceUnit { PerformanceUnit(rawValue: unitRaw) ?? .seconds }
    var context: PerformanceContext { PerformanceContext(rawValue: contextRaw) ?? .training }
    var timing: TimingMethod? {
        guard let timingRaw else { return nil }
        return TimingMethod(rawValue: timingRaw)
    }
}

@Model
final class FoodLogEntry {
    @Attribute(.unique) var id: UUID
    var date: Date
    var servings: Double
    var slotLabel: String
    var sourceRaw: String
    var meal: Meal?
    var food: Food?

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        meal: Meal? = nil,
        food: Food? = nil,
        servings: Double = 1,
        slot: String = "Snack",
        source: FoodLogSource = .unplanned
    ) {
        self.id = id
        self.date = date
        self.meal = meal
        self.food = food
        self.servings = servings
        self.slotLabel = slot
        self.sourceRaw = source.rawValue
    }
}

@Model
final class BodyWeightEntry {
    @Attribute(.unique) var id: UUID
    var date: Date
    var weightKg: Double
    var sourceRaw: String

    init(id: UUID = UUID(), date: Date = Date(), weightKg: Double, source: WeightSource = .manual) {
        self.id = id
        self.date = date
        self.weightKg = weightKg
        self.sourceRaw = source.rawValue
    }
}

@Model
final class GroceryCheck {
    @Attribute(.unique) var id: UUID
    var weekStart: Date
    var itemKey: String
    var isChecked: Bool

    init(id: UUID = UUID(), weekStart: Date, itemKey: String, isChecked: Bool = false) {
        self.id = id
        self.weekStart = weekStart
        self.itemKey = itemKey
        self.isChecked = isChecked
    }
}

enum PlatesModelContainer {
    static let schema = Schema([
        UserProfile.self,
        Exercise.self,
        ExerciseVariationGroup.self,
        Routine.self,
        RoutineItem.self,
        Program.self,
        WeekSchedule.self,
        WorkoutSession.self,
        SetLog.self,
        Food.self,
        Meal.self,
        MealIngredient.self,
        DayPlan.self,
        PlannedMeal.self,
        FoodLogEntry.self,
        BodyWeightEntry.self,
        GroceryCheck.self,
        TrainingSession.self,
        TrainingBlock.self,
        TrainingBlockItem.self,
        TrackEvent.self,
        PerformanceRecord.self,
        V2PersistedState.self,
    ])

    static func make(inMemory: Bool = false) -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: inMemory)
        return try! ModelContainer(for: schema, configurations: [config])
    }
}
