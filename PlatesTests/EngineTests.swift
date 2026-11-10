import XCTest
@testable import Plates

final class EngineTests: XCTestCase {
    func testDayLoadSprintNeural() {
        let spec = HybridItemSpec(
            kind: .sprint,
            distanceM: 30,
            sprintReps: 4,
            sprintSets: 1,
            intensityPct: 95
        )
        let input = DayLoadEngine.BlockLoadInput(
            type: .sprint,
            spec: spec,
            result: nil,
            durationMinutes: 25,
            bodyWeightKg: 75
        )
        let load = DayLoadEngine.load(for: input)
        XCTAssertGreaterThan(load.neural, 10)
        XCTAssertGreaterThan(load.energyKcal, 100)
    }

    func testAccountabilityDayScore() {
        let perfect = DayAccountabilityInput(
            date: Date(),
            isTrainingDay: true,
            workoutCompleted: true,
            proteinRatio: 0.9,
            fuelAdherenceRatio: 0.95
        )
        let score = AccountabilityEngine.dayScore(perfect)
        XCTAssertGreaterThanOrEqual(score, 68)
        XCTAssertTrue(AccountabilityEngine.metPlan(score: score))

        let rest = DayAccountabilityInput(
            date: Date(),
            isTrainingDay: false,
            workoutCompleted: false,
            proteinRatio: 0.2,
            fuelAdherenceRatio: 0.2
        )
        XCTAssertFalse(AccountabilityEngine.metPlan(score: AccountabilityEngine.dayScore(rest)))
    }

    func testBMRFloorsAndGoalMultipliers() {
        let bmr = TargetsEngine.bmrKgCmAge(sex: .male, weightKg: 80, heightCm: 180, ageYears: 30)
        XCTAssertGreaterThan(bmr, 1700)
        XCTAssertEqual(TargetsEngine.goalCalorieMultiplier(goals: [.loseFat]), 0.85, accuracy: 0.01)
        XCTAssertEqual(TargetsEngine.goalCalorieMultiplier(goals: [.buildMuscle]), 1.08, accuracy: 0.01)
        let floor = TargetsEngine.calorieFloor(bmr: bmr)
        XCTAssertGreaterThanOrEqual(floor, 1400)
    }

    func testTrainingDayCyclingWeeklyBudget() {
        var profile = UserProfile(
            sex: .male,
            goals: [.getStronger],
            foodDetail: .balanced,
            trainingDaysPerWeek: 4,
            bodyWeightKg: 80
        )
        profile.birthDate = Calendar.current.date(byAdding: .year, value: -30, to: Date())!
        let week: [WeekDayTargetInput] = [
            .init(weekday: 2, dayType: .heavy),
            .init(weekday: 4, dayType: .standard),
            .init(weekday: 6, dayType: .light),
        ]
        let heavyDay = TargetsEngine.dailyTargets(profile: profile, trendWeightKg: 80, weekPlan: week, date: date(weekday: 2))
        let restDay = TargetsEngine.dailyTargets(profile: profile, trendWeightKg: 80, weekPlan: week, date: date(weekday: 1))
        XCTAssertGreaterThan(heavyDay.kcal, restDay.kcal)
        XCTAssertGreaterThan(heavyDay.carbsG, restDay.carbsG)
    }

    func testCarbsFloorAdjustsFat() {
        var profile = UserProfile(sex: .female, goals: [.loseFat], trainingDaysPerWeek: 2, bodyWeightKg: 55)
        profile.birthDate = Calendar.current.date(byAdding: .year, value: -40, to: Date())!
        let week = [WeekDayTargetInput(weekday: 3, dayType: .light)]
        let targets = TargetsEngine.dailyTargets(profile: profile, trendWeightKg: 55, weekPlan: week, date: date(weekday: 3))
        XCTAssertGreaterThanOrEqual(targets.kcal, 1400)
        XCTAssertGreaterThanOrEqual(targets.carbsG, 0)
    }

    func testTrendEngineEWMA() {
        let d0 = Date()
        let entries: [(Date, Double)] = [
            (d0, 80), (d0.addingDays(1), 80.2), (d0.addingDays(2), 79.8),
        ]
        let trend = TrendEngine.trendToday(entries: entries)
        XCTAssertNotNil(trend)
        XCTAssertEqual(trend!, 80, accuracy: 0.5)
    }

    func testProgressionAddsWeightWhenAllRepsHit() {
        let last = SessionPerformance(sets: [
            SetPerformance(weightKg: 100, reps: 8, isWarmup: false),
            SetPerformance(weightKg: 100, reps: 8, isWarmup: false),
        ])
        let target = ProgressionEngine.nextTarget(
            repMin: 5, repMax: 8,
            lastSession: last, priorSession: nil,
            lastWeightKg: 100, isLowerBody: false, units: .lb, isDeloadWeek: false
        )
        XCTAssertGreaterThan(target.weightKg, 100)
    }

    func testEpleyOneRM() {
        let e1rm = ProgressionEngine.estimatedOneRepMaxKg(weightKg: 100, reps: 5)
        XCTAssertEqual(e1rm!, 116.67, accuracy: 0.1)
        XCTAssertNil(ProgressionEngine.estimatedOneRepMaxKg(weightKg: 100, reps: 15))
    }

    func testReadinessLabels() {
        let good = ReadinessEngine.score(
            hrvTodayMs: 60, hrvBaselineMs: 50, hrvStdMs: 5,
            restingHRToday: 55, restingHRBaseline: 60, restingHRStd: 3,
            sleepHours: 8
        )
        XCTAssertTrue(good.hasData)
        XCTAssertGreaterThanOrEqual(good.score, 67)
    }

    func testWeeklyAdjustRequiresData() {
        let result = WeeklyAdjustEngine.adjust(
            previousMaintenanceKcal: 2500,
            averageDailyIntakeKcal: 2400,
            trendChangeKg: -0.3,
            daysInSample: 14,
            daysWithFoodLogged: 5,
            weighInCount: 4,
            goal: .loseFat
        )
        XCTAssertFalse(result.applied)
    }

    func testGroceryAggregation() {
        let id = UUID()
        let items = GroceryEngine.aggregate(ingredients: [
            .init(foodID: id, foodName: "Chicken", aisle: .protein, totalServings: 2, servingName: "4 oz", servingGrams: 113, mealNames: ["Bowl"]),
            .init(foodID: id, foodName: "Chicken", aisle: .protein, totalServings: 1, servingName: "4 oz", servingGrams: 113, mealNames: ["Salad"]),
        ])
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items[0].mealNames.count, 2)
    }

    private func date(weekday: Int) -> Date {
        var comps = DateComponents()
        comps.weekday = weekday
        comps.hour = 12
        return Calendar.current.nextDate(after: Date(), matching: comps, matchingPolicy: .nextTime) ?? Date()
    }
}

private extension Date {
    func addingDays(_ n: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: n, to: self)!
    }
}
