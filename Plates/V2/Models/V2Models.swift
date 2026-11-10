import Foundation

enum Effort: String, Codable, CaseIterable, Identifiable {
    case light = "Light"
    case medium = "Medium"
    case hard = "Hard"
    var id: String { rawValue }
}

enum MealSlot: String, Codable, CaseIterable, Identifiable {
    case breakfast, lunch, dinner, snacks
    var id: String { rawValue }

    var title: String {
        switch self {
        case .breakfast: "Breakfast"
        case .lunch: "Lunch"
        case .dinner: "Dinner"
        case .snacks: "Snacks"
        }
    }
}

enum FoodArt: String, Codable {
    case bowl, plate, glass, bar
}

struct FuelMeal: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var slot: MealSlot
    var kcal: Int
    var protein: Int
    var carbs: Int
    var fat: Int
    var isFavorite: Bool
    var art: FoodArt
    var colors: [String]
}

struct SplitDay: Codable, Equatable {
    var weekday: Int
    var workout: String
    var effort: Effort?
}

struct FuelDayPlan: Codable, Equatable {
    var date: Date
    var picks: [MealSlot: UUID]
    var locked: Set<MealSlot>

    init(date: Date, picks: [MealSlot: UUID] = [:], locked: Set<MealSlot> = []) {
        self.date = date
        self.picks = picks
        self.locked = locked
    }

    enum CodingKeys: String, CodingKey { case date, picks, locked }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        date = try c.decode(Date.self, forKey: .date)
        let rawPicks = try c.decode([String: UUID].self, forKey: .picks)
        picks = Dictionary(uniqueKeysWithValues: rawPicks.compactMap { key, value in
            MealSlot(rawValue: key).map { ($0, value) }
        })
        let rawLocked = try c.decode([String].self, forKey: .locked)
        locked = Set(rawLocked.compactMap(MealSlot.init(rawValue:)))
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(date, forKey: .date)
        try c.encode(Dictionary(uniqueKeysWithValues: picks.map { ($0.key.rawValue, $0.value) }), forKey: .picks)
        try c.encode(locked.map(\.rawValue), forKey: .locked)
    }
}

struct CheckIn: Codable, Equatable {
    var date: Date
    var feel: Int
    var tags: [String]
    var ateYesterday: String
    var missedMealIDs: [UUID]
}

struct TargetSettings: Codable, Equatable {
    var baseKcal: Int = 1_950
    var protein: Int = 180
    var baseCarbs: Int = 180
    var fat: Int = 65
}

struct MacroTargets: Equatable {
    var kcal: Int
    var protein: Int
    var carbs: Int
    var fat: Int
}

struct V2Snapshot: Codable {
    var meals: [FuelMeal]
    var split: [SplitDay]
    var dayPlans: [String: FuelDayPlan]
    var settings: TargetSettings

    static let storageKey = "v2.snapshot"
}

extension FuelDayPlan {
    static func dayKey(_ date: Date) -> String {
        let start = Calendar.current.startOfDay(for: date)
        return ISO8601DateFormatter().string(from: start)
    }
}
