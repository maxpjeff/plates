import Foundation

struct DailyTargetsResult: Equatable {
    let date: Date
    let dayType: DayType
    let kcal: Int
    let proteinG: Int
    let carbsG: Int
    let fatG: Int
    let reason: String
}

struct WeekDayTargetInput: Equatable {
    let weekday: Int
    let dayType: DayType
}

struct ProgressionTarget: Equatable {
    let weightKg: Double
    let repMin: Int
    let repMax: Int
    let note: String
}

struct SetPerformance: Equatable {
    let weightKg: Double
    let reps: Int
    let isWarmup: Bool
}

struct SessionPerformance: Equatable {
    let sets: [SetPerformance]
}

struct GroceryLineItem: Equatable, Identifiable {
    var id: String { itemKey }
    let itemKey: String
    let name: String
    let quantityLabel: String
    let aisle: GroceryAisle
    let mealNames: [String]
}

struct ReadinessResult: Equatable {
    let score: Int
    let label: String
    let hasData: Bool
}

struct WeeklyAdjustResult: Equatable {
    let applied: Bool
    let newMaintenanceKcal: Int
    let deltaKcal: Int
    let summary: String
}
