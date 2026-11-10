import Foundation
import SwiftUI
import SwiftData

@Observable
@MainActor
final class FuelStore {
    var selectedDate: Date
    var meals: [FuelMeal]
    var split: [SplitDay]
    var settings: TargetSettings
    private var dayPlansByKey: [String: FuelDayPlan]
    var userName: String = "Alex"

    /// Per-slot scroll index for rails (which meal is centered).
    var railIndex: [MealSlot: Int] = [:]

    init() {
        selectedDate = V2MockData.startMonday
        meals = V2MockData.meals
        split = V2MockData.split
        settings = V2MockData.settings
        dayPlansByKey = [:]
        seedInitialPlans()
        syncRailIndices()
    }

    func load(from context: ModelContext) {
        if let state = try? context.fetch(FetchDescriptor<V2PersistedState>()).first,
           let snapshot = try? JSONDecoder().decode(V2Snapshot.self, from: state.payload) {
            meals = snapshot.meals
            split = snapshot.split
            settings = snapshot.settings
            dayPlansByKey = snapshot.dayPlans
        } else {
            save(context: context)
        }
        syncRailIndices()
    }

    func save(context: ModelContext) {
        let snapshot = V2Snapshot(meals: meals, split: split, dayPlans: dayPlansByKey, settings: settings)
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        let descriptor = FetchDescriptor<V2PersistedState>()
        if let existing = try? context.fetch(descriptor).first {
            existing.payload = data
        } else {
            context.insert(V2PersistedState(payload: data))
        }
        try? context.save()
    }

    private func seedInitialPlans() {
        var date = V2MockData.startMonday
        for _ in 0..<14 {
            let key = FuelDayPlan.dayKey(date)
            if dayPlansByKey[key] == nil {
                dayPlansByKey[key] = V2MockData.defaultPlan(for: date, meals: meals)
            }
            date = Calendar.current.date(byAdding: .day, value: 1, to: date) ?? date
        }
    }

    func plan(for date: Date) -> FuelDayPlan {
        let key = FuelDayPlan.dayKey(date)
        if let plan = dayPlansByKey[key] { return plan }
        let plan = V2MockData.defaultPlan(for: date, meals: meals)
        dayPlansByKey[key] = plan
        return plan
    }

    func updatePlan(_ plan: FuelDayPlan) {
        dayPlansByKey[FuelDayPlan.dayKey(plan.date)] = plan
    }

    func split(for date: Date) -> SplitDay {
        let wd = V2Calendar.specWeekday(date)
        return split.first { $0.weekday == wd } ?? SplitDay(weekday: wd, workout: "Rest", effort: nil)
    }

    func targets(for date: Date) -> MacroTargets {
        TargetCalculator.targets(for: split(for: date), settings: settings)
    }

    func meals(for slot: MealSlot) -> [FuelMeal] {
        meals.filter { $0.slot == slot }
    }

    func selectedMealID(slot: MealSlot, date: Date) -> UUID? {
        plan(for: date).picks[slot]
    }

    func selectedMeal(slot: MealSlot, date: Date) -> FuelMeal? {
        guard let id = selectedMealID(slot: slot, date: date) else { return nil }
        return meals.first { $0.id == id }
    }

    func isLocked(slot: MealSlot, date: Date) -> Bool {
        plan(for: date).locked.contains(slot)
    }

    func setSelectedMeal(slot: MealSlot, mealID: UUID, date: Date) {
        guard !isLocked(slot: slot, date: date) else { return }
        var plan = plan(for: date)
        plan.picks[slot] = mealID
        updatePlan(plan)
        if let idx = meals(for: slot).firstIndex(where: { $0.id == mealID }) {
            railIndex[slot] = idx
        }
    }

    func toggleLock(slot: MealSlot, date: Date) {
        var plan = plan(for: date)
        if plan.locked.contains(slot) {
            plan.locked.remove(slot)
        } else {
            plan.locked.insert(slot)
        }
        updatePlan(plan)
    }

    func shuffle(date: Date) {
        var plan = plan(for: date)
        for slot in MealSlot.allCases where !plan.locked.contains(slot) {
            let options = meals(for: slot)
            if let pick = options.randomElement() {
                plan.picks[slot] = pick.id
                if let idx = options.firstIndex(where: { $0.id == pick.id }) {
                    railIndex[slot] = idx
                }
            }
        }
        updatePlan(plan)
    }

    func fitMyDay(date: Date) -> Bool {
        let target = targets(for: date)
        var plan = plan(for: date)
        let lockedSlots = plan.locked

        func candidates(for slot: MealSlot) -> [FuelMeal] {
            let all = meals(for: slot)
            let sorted = all.sorted { lhs, rhs in
                if lhs.isFavorite != rhs.isFavorite { return lhs.isFavorite }
                return lhs.name < rhs.name
            }
            return Array(sorted.prefix(12))
        }

        var bestScore = Double.infinity
        var bestPicks = plan.picks

        func search(slotIndex: Int, current: [MealSlot: UUID]) {
            if slotIndex == MealSlot.allCases.count {
                let score = fitScore(picks: current, target: target)
                if score < bestScore {
                    bestScore = score
                    bestPicks = current
                }
                return
            }
            let slot = MealSlot.allCases[slotIndex]
            if lockedSlots.contains(slot), let id = plan.picks[slot] {
                var next = current
                next[slot] = id
                search(slotIndex: slotIndex + 1, current: next)
                return
            }
            for meal in candidates(for: slot) {
                var next = current
                next[slot] = meal.id
                search(slotIndex: slotIndex + 1, current: next)
            }
        }

        search(slotIndex: 0, current: [:])
        plan.picks = bestPicks
        updatePlan(plan)
        syncRailIndices(for: date)
        return true
    }

    private func fitScore(picks: [MealSlot: UUID], target: MacroTargets) -> Double {
        var kcal = 0, p = 0, c = 0, f = 0
        for (_, id) in picks {
            guard let meal = meals.first(where: { $0.id == id }) else { continue }
            kcal += meal.kcal
            p += meal.protein
            c += meal.carbs
            f += meal.fat
        }
        func norm(_ diff: Int, _ t: Int) -> Double {
            guard t > 0 else { return 0 }
            return abs(Double(diff)) / Double(t)
        }
        return norm(kcal - target.kcal, target.kcal)
            + 2 * norm(p - target.protein, target.protein)
            + norm(c - target.carbs, target.carbs)
            + norm(f - target.fat, target.fat)
    }

    func totals(for date: Date) -> (kcal: Int, protein: Int, carbs: Int, fat: Int) {
        var kcal = 0, p = 0, c = 0, f = 0
        let plan = plan(for: date)
        for slot in MealSlot.allCases {
            guard let id = plan.picks[slot], let meal = meals.first(where: { $0.id == id }) else { continue }
            kcal += meal.kcal
            p += meal.protein
            c += meal.carbs
            f += meal.fat
        }
        return (kcal, p, c, f)
    }

    func updateSplitDay(_ day: SplitDay) {
        if let idx = split.firstIndex(where: { $0.weekday == day.weekday }) {
            split[idx] = day
        } else {
            split.append(day)
        }
    }

    func syncRailIndices(for date: Date? = nil) {
        let d = date ?? selectedDate
        for slot in MealSlot.allCases {
            let list = meals(for: slot)
            if let id = plan(for: d).picks[slot], let idx = list.firstIndex(where: { $0.id == id }) {
                railIndex[slot] = idx
            } else {
                railIndex[slot] = 0
            }
        }
    }

    func moveRail(slot: MealSlot, delta: Int, date: Date) {
        guard !isLocked(slot: slot, date: date) else { return }
        let list = meals(for: slot)
        guard !list.isEmpty else { return }
        let current = railIndex[slot] ?? 0
        let next = min(list.count - 1, max(0, current + delta))
        railIndex[slot] = next
        setSelectedMeal(slot: slot, mealID: list[next].id, date: date)
    }
}

enum V2Calendar {
    static func specWeekday(_ date: Date) -> Int {
        let w = Calendar.current.component(.weekday, from: date)
        return w == 1 ? 7 : w - 1
    }

    static func relativeDayLabel(for date: Date, today: Date = Calendar.current.startOfDay(for: Date())) -> String {
        let start = Calendar.current.startOfDay(for: date)
        let diff = Calendar.current.dateComponents([.day], from: today, to: start).day ?? 0
        switch diff {
        case 0: return "Today"
        case 1: return "Tomorrow"
        case -1: return "Yesterday"
        case let d where d > 1: return "In \(d) days"
        default: return "\(abs(diff)) days ago"
        }
    }
}

@Model
final class V2PersistedState {
    @Attribute(.unique) var singleton: String
    var payload: Data

    init(payload: Data, singleton: String = "v2") {
        self.singleton = singleton
        self.payload = payload
    }
}
