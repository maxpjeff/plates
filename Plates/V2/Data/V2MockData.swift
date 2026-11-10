import Foundation

enum V2MockData {
    static var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "America/Los_Angeles") ?? .current
        return cal
    }

    static var startMonday: Date {
        var c = DateComponents()
        c.year = 2026; c.month = 11; c.day = 2
        return calendar.startOfDay(for: calendar.date(from: c)!)
    }

    static var settings: TargetSettings {
        TargetSettings(baseKcal: 1_950, protein: 180, baseCarbs: 180, fat: 65)
    }

    static var split: [SplitDay] {
        [
            SplitDay(weekday: 1, workout: "Sprints", effort: .hard),
            SplitDay(weekday: 2, workout: "Push", effort: .medium),
            SplitDay(weekday: 3, workout: "Tempo run", effort: .light),
            SplitDay(weekday: 4, workout: "Legs", effort: .hard),
            SplitDay(weekday: 5, workout: "Pull", effort: .medium),
            SplitDay(weekday: 6, workout: "Long run", effort: .medium),
            SplitDay(weekday: 7, workout: "Rest", effort: nil),
        ]
    }

    /// Five meals per slot — names/macros aligned with v2 Fuel mockup intent.
    static var meals: [FuelMeal] {
        [
            meal("Overnight oats", .breakfast, 480, 28, 62, 14, true, .bowl, ["D9896A", "8FAF88", "E8B49A"]),
            meal("Greek yogurt bowl", .breakfast, 420, 32, 48, 12, false, .bowl, ["FBECE3", "BFD0B6", "E8B49A"]),
            meal("Egg & avocado toast", .breakfast, 510, 26, 44, 24, true, .plate, ["E8B49A", "8FAF88", "33302C"]),
            meal("Protein pancakes", .breakfast, 540, 34, 58, 16, false, .plate, ["D9896A", "F3EEE6", "8FAF88"]),
            meal("Berry smoothie", .breakfast, 390, 24, 52, 8, false, .glass, ["D9896A", "8FAF88", "BFD0B6"]),

            meal("Chicken rice bowl", .lunch, 620, 48, 72, 14, true, .bowl, ["8FAF88", "E8B49A", "33302C"]),
            meal("Turkey wrap", .lunch, 580, 42, 54, 18, false, .plate, ["FBECE3", "8FAF88", "E8B49A"]),
            meal("Salmon salad", .lunch, 560, 44, 28, 32, true, .plate, ["D9896A", "8FAF88", "BFD0B6"]),
            meal("Pasta & meatballs", .lunch, 680, 38, 86, 20, false, .bowl, ["E8B49A", "33302C", "8FAF88"]),
            meal("Tuna poke bowl", .lunch, 590, 40, 68, 16, false, .bowl, ["8FAF88", "D9896A", "FBECE3"]),

            meal("Steak & potatoes", .dinner, 720, 52, 58, 28, true, .plate, ["33302C", "E8B49A", "8FAF88"]),
            meal("Salmon & quinoa", .dinner, 640, 46, 52, 24, false, .plate, ["D9896A", "8FAF88", "F3EEE6"]),
            meal("Chicken stir-fry", .dinner, 610, 44, 64, 18, true, .bowl, ["8FAF88", "E8B49A", "33302C"]),
            meal("Burrito bowl", .dinner, 690, 38, 78, 22, false, .bowl, ["E8B49A", "8FAF88", "D9896A"]),
            meal("Shrimp tacos", .dinner, 580, 36, 48, 20, false, .plate, ["FBECE3", "D9896A", "8FAF88"]),

            meal("Protein bar", .snacks, 220, 20, 24, 8, true, .bar, ["E8B49A", "33302C"]),
            meal("Apple & peanut butter", .snacks, 280, 10, 32, 14, false, .plate, ["8FAF88", "D9896A"]),
            meal("Cottage cheese cup", .snacks, 180, 24, 12, 4, false, .bowl, ["FBECE3", "8FAF88"]),
            meal("Trail mix", .snacks, 260, 8, 28, 14, false, .bar, ["D9896A", "E8B49A", "8FAF88"]),
            meal("Chocolate milk", .snacks, 210, 12, 30, 6, true, .glass, ["33302C", "FBECE3"]),
        ]
    }

    private static func meal(
        _ name: String,
        _ slot: MealSlot,
        _ kcal: Int,
        _ p: Int,
        _ c: Int,
        _ f: Int,
        _ fav: Bool,
        _ art: FoodArt,
        _ colors: [String]
    ) -> FuelMeal {
        FuelMeal(id: UUID(), name: name, slot: slot, kcal: kcal, protein: p, carbs: c, fat: f, isFavorite: fav, art: art, colors: colors)
    }

    static func defaultPlan(for date: Date, meals: [FuelMeal]) -> FuelDayPlan {
        var picks: [MealSlot: UUID] = [:]
        for slot in MealSlot.allCases {
            picks[slot] = meals.filter { $0.slot == slot }.first?.id
        }
        return FuelDayPlan(date: date, picks: picks, locked: [])
    }
}
