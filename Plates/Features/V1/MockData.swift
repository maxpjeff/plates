import Foundation
import SwiftUI

enum MockData {
    static var referenceCalendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "America/Los_Angeles") ?? .current
        return cal
    }

    static var today: Date {
        var c = DateComponents()
        c.year = 2026
        c.month = 11
        c.day = 4
        c.hour = 12
        return referenceCalendar.date(from: c) ?? Date()
    }

    static var weekDays: [DayStripModel] {
        let loads: [DayLoadLabel] = [.rest, .high, .moderate, .high, .low, .high, .low]
        let labels = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        return (1...7).map { day in
            DayStripModel(
                weekday: labels[day - 1],
                dateNumber: day,
                load: loads[day - 1],
                isSelected: day == 4
            )
        }
    }

    static var weekPlan: [PlanDayModel] {
        let loads: [(DayLoadLabel, String, [PlanChipStyle], Int, CGFloat)] = [
            (.rest, "Rest day", [.standard("Walk + mobility")], 1_900, 18),
            (.high, "Speed + Upper", [.standard("Sprint"), .standard("Lift")], 2_190, 118),
            (.moderate, "Tempo run", [.standard("Run · 4 mi"), .standard("via Strava")], 2_110, 74),
            (.high, "Speed + Lower", [.standard("Sprint"), .standard("Plyo"), .standard("Lift")], 2_180, 112),
            (.low, "Mobility + core", [.standard("Lift"), .ptGuided("PT-guided")], 1_980, 40),
            (.high, "Jumps + Pull", [.standard("Jumps · short approach"), .standard("Lift")], 2_200, 124),
            (.low, "Easy run", [.standard("Run · 3 mi")], 2_050, 46),
        ]
        let labels = ["Sun", "Mon", "Tue", "Today", "Thu", "Fri", "Sat"]
        return (1...7).map { index in
            var c = DateComponents()
            c.year = 2026; c.month = 11; c.day = index
            let date = referenceCalendar.date(from: c) ?? today
            let row = loads[index - 1]
            return PlanDayModel(
                date: date,
                day: index,
                weekdayLabel: labels[index - 1],
                isToday: index == 4,
                load: row.0,
                title: row.1,
                chips: row.2,
                kcal: row.3,
                barHeight: row.4
            )
        }
    }

    static var todayModel: TodayScreenModel {
        TodayScreenModel(
            overline: "Wednesday, Nov 4",
            profileInitials: "M",
            dayStrip: weekDays,
            load: .high,
            sessionSubtitle: "Speed + Lower · 12:00 PM",
            kcalLeft: 1_580,
            kcalEaten: 600,
            kcalTarget: 2_180,
            calorieProgress: 0.28,
            proteinEaten: 20, proteinTarget: 126, proteinPercent: 0.16,
            carbsEaten: 116, carbsTarget: 246, carbsPercent: 0.47,
            fatEaten: 9, fatTarget: 77, fatPercent: 0.12,
            mealsCount: 5,
            sessionsCount: 1,
            timeline: timelineItems
        )
    }

    static var fuelModel: FuelScreenModel {
        FuelScreenModel(
            overline: "Goal · Lean gain",
            dayStrip: weekDays,
            load: .high,
            kcalEaten: 600,
            kcalTarget: 2_180,
            calorieProgress: 0.28,
            kcalLeft: 1_580,
            fuelBreakdown: "Base 1,900 + 280 for today's session",
            proteinEaten: 20, proteinTarget: 126, proteinLeft: 106, proteinPercent: 0.16,
            carbsEaten: 116, carbsTarget: 246, carbsLeft: 130, carbsPercent: 0.47,
            fatEaten: 9, fatTarget: 77, fatLeft: 68, fatPercent: 0.12,
            gapTitle: "Plan is 90 kcal short",
            gapBody: "Add a banana to your 4:30 snack (+105 kcal)",
            foods: foodRows,
            eatenCount: 2,
            plannedCount: 3
        )
    }

    static var planModel: PlanScreenModel {
        PlanScreenModel(
            overline: "Nov 1 – Nov 7",
            loadSummary: "3 high · 2 moderate-low · 1 rest",
            chartDays: weekPlan.map { LoadChartDay(letter: chartLetter($0.day), load: $0.load, barHeight: $0.barHeight, isToday: $0.isToday) },
            days: weekPlan
        )
    }

    static var progressModel: ProgressScreenModel {
        var octoberCompletion: [Int: Int] = [:]
        let values = [100, 100, 60, 100, 100, 100, 30, 100, 100, 100, 75, 100, 100, 100, 0, 100, 50, 100, 100, 100, 100, 100, 100, 100, 85, 100, 100, 100, 40, 100, 0]
        for (index, pct) in values.enumerated() {
            octoberCompletion[index + 1] = pct
        }
        var cal = referenceCalendar
        var c = DateComponents()
        c.year = 2026; c.month = 10; c.day = 1
        let october = cal.date(from: c) ?? today

        let goals: [ProgressGoalRowModel] = [
            .init(id: UUID(), title: "Long jump · 7.40 m", remaining: "0.22 m to go", progress: 0.56, nowLine: "Now 7.18 m", deadlineLine: "by Jun 2027"),
            .init(id: UUID(), title: "Front squat · 315 lb", remaining: "30 lb to go", progress: 0.57, nowLine: "Now 285 lb (est. 1RM)", deadlineLine: "by Mar 2027"),
            .init(id: UUID(), title: "Body weight · 185 lb", remaining: "3.6 lb to go", progress: 0.49, nowLine: "Now 181.4 lb · lean gain", deadlineLine: "by Jan 2027"),
        ]

        let competition: [PersonalRecordRow] = [
            .init(id: UUID(), name: "Long jump", context: "Conference Champs · May 2026", value: "7.18 m", detail: "+1.4 m/s · legal"),
            .init(id: UUID(), name: "Long jump", context: "Invitational · Apr 2026", value: "7.31w", detail: "+2.6 m/s", tagWindAided: true, valueIsMuted: true),
            .init(id: UUID(), name: "110m hurdles", context: "Conference Champs · May 2026", value: "14.62", detail: "FAT · +0.8 m/s"),
            .init(id: UUID(), name: "60m hurdles", context: "Indoor Open · Feb 2026", value: "8.21", detail: "FAT · indoor"),
        ]
        let training: [PersonalRecordRow] = [
            .init(id: UUID(), name: "30 m fly", context: "Speed + Lower · Oct 28", value: "2.90 s", detail: "Laser", tagNew: true),
            .init(id: UUID(), name: "Short-approach LJ", context: "6 strides · Oct 16", value: "6.62 m", detail: "Measured"),
            .init(id: UUID(), name: "5-hurdle run", context: "Race spacing · Oct 9", value: "6.84 s", detail: "Hand"),
            .init(id: UUID(), name: "Standing triple jump", context: "Oct 2", value: "9.12 m", detail: "Measured"),
        ]
        let lift: [PersonalRecordRow] = [
            .init(id: UUID(), name: "Front squat", context: "4 × 3 @ 255 lb · Oct 30", value: "285 lb", detail: "est. 1RM"),
            .init(id: UUID(), name: "Power clean", context: "Tested · Oct 24", value: "245 lb", detail: "1RM", tagNew: true),
            .init(id: UUID(), name: "Trap bar deadlift", context: "3 × 5 @ 365 lb · Oct 12", value: "425 lb", detail: "est. 1RM"),
            .init(id: UUID(), name: "Weighted chin-up", context: "+45 lb × 6 · Oct 7", value: "+70 lb", detail: "est. 1RM"),
        ]

        return ProgressScreenModel(
            overline: "Week of Nov 1",
            score: 82,
            streakDays: 9,
            vsLastWeek: 3,
            calendarMonth: october,
            dayCompletionByDay: octoberCompletion,
            bestWeekScore: 88,
            messageTitle: "6 points from your best week.",
            messageSubtitle: "Stack a few full days and set a new high.",
            goals: goals,
            prsByCategory: [.competition: competition, .training: training, .lift: lift]
        )
    }

    static var liveSessionModel: LiveSessionModel {
        LiveSessionModel(
            elapsed: "18:42",
            title: "Speed + Lower",
            blockProgress: "Block 1 of 3 · Sprint",
            segmentFill: [0.55, 0, 0],
            exerciseTitle: "30 m fly @ 95%",
            exerciseSubtitle: "Target 3.05 s · PR 2.90 s (FAT)",
            restLabel: "Rest 0:48",
            reps: [
                .done(label: "Rep 1", value: "3.08 s", trailing: .meta("Hand · +0.8")),
                .done(label: "Rep 2", value: "3.03 s", trailing: .onTarget),
                .active(label: "Rep 3", partial: "3.0"),
                .pending(label: "Rep 4"),
            ],
            timingPills: ["Hand", "FAT", "Laser"],
            selectedTiming: "Hand",
            wind: "Wind +1.2"
        )
    }

    private static func dateFor(day: Int) -> Date {
        var c = DateComponents()
        c.year = 2026; c.month = 11; c.day = day
        return referenceCalendar.date(from: c) ?? today
    }

    private static func chartLetter(_ day: Int) -> String {
        ["S", "M", "T", "W", "T", "F", "S"][day - 1]
    }

    private static var timelineItems: [TodayTimelineItem] {
        [
            .meal(MealTimelineModel(time: "8:00 AM", role: "Breakfast", name: "Oats & berries bowl", kcal: 420, protein: 18, carbs: 72, fat: 9, eaten: true)),
            .meal(MealTimelineModel(time: "10:45 AM", role: "Pre-session", name: "Banana & honey", kcal: 180, protein: 2, carbs: 44, fat: 0, eaten: true)),
            .session(SessionTimelineModel(
                time: "12:00 PM",
                caps: "SESSION · 3 BLOCKS · ~75 MIN",
                title: "Speed + Lower",
                blocks: [
                    SessionBlockRow(icon: "bolt", name: "Sprint", detail: "4 × 30 m fly @ 95% · 4 min rest"),
                    SessionBlockRow(icon: "arrow.up", name: "Plyo", detail: "Pogos + bounds · 60 contacts"),
                    SessionBlockRow(icon: "dumbbell", name: "Lift", detail: "Front squat 4 × 3 · Nordics 3 × 5"),
                ],
                before: BeforeCardModel(
                    goalChip: "Goal · 30 m fly under 3.00 s",
                    note: "Legs feel fresh. Slept 8 hrs. Focus on staying tall through the zone."
                ),
                after: nil
            )),
            .meal(MealTimelineModel(time: "2:00 PM", role: "Post-session", name: "Chicken & rice", kcal: 620, protein: 52, carbs: 78, fat: 10, eaten: false)),
            .meal(MealTimelineModel(time: "4:30 PM", role: "Snack", name: "Greek yogurt parfait", kcal: 310, protein: 28, carbs: 36, fat: 6, eaten: false)),
            .meal(MealTimelineModel(time: "7:30 PM", role: "Dinner", name: "Salmon & quinoa", kcal: 560, protein: 38, carbs: 48, fat: 22, eaten: false)),
        ]
    }

    private static var foodRows: [FoodRowModel] {
        [
            FoodRowModel(name: "Oats & berries bowl", icon: "cup.and.saucer", protein: 18, carbs: 72, fat: 9, kcal: 420, time: "8:00 AM", planned: false),
            FoodRowModel(name: "Banana & honey", icon: "leaf", protein: 2, carbs: 44, fat: 0, kcal: 180, time: "10:45 AM", planned: false),
            FoodRowModel(name: "Chicken & rice", icon: "fork.knife", protein: 52, carbs: 78, fat: 10, kcal: 620, time: "2:00 PM", planned: true),
            FoodRowModel(name: "Greek yogurt parfait", icon: "cup.and.saucer", protein: 28, carbs: 36, fat: 6, kcal: 310, time: "4:30 PM", planned: true),
            FoodRowModel(name: "Salmon & quinoa", icon: "fish", protein: 38, carbs: 48, fat: 22, kcal: 560, time: "7:30 PM", planned: true),
        ]
    }
}

// MARK: - Screen models

struct DayStripModel: Identifiable {
    var id: Int { dateNumber }
    let weekday: String
    let dateNumber: Int
    let load: DayLoadLabel
    let isSelected: Bool
}

struct TodayScreenModel {
    let overline: String
    let profileInitials: String
    let dayStrip: [DayStripModel]
    let load: DayLoadLabel
    let sessionSubtitle: String
    let kcalLeft: Int
    let kcalEaten: Int
    let kcalTarget: Int
    let calorieProgress: Double
    let proteinEaten: Int
    let proteinTarget: Int
    let proteinPercent: Double
    let carbsEaten: Int
    let carbsTarget: Int
    let carbsPercent: Double
    let fatEaten: Int
    let fatTarget: Int
    let fatPercent: Double
    let mealsCount: Int
    let sessionsCount: Int
    let timeline: [TodayTimelineItem]
}

enum TodayTimelineItem: Identifiable {
    case meal(MealTimelineModel)
    case session(SessionTimelineModel)

    var id: String {
        switch self {
        case .meal(let m): "meal-\(m.time)"
        case .session(let s): "session-\(s.time)"
        }
    }
}

struct MealTimelineModel {
    let time: String
    let role: String
    let name: String
    let kcal: Int
    let protein: Int
    let carbs: Int
    let fat: Int
    let eaten: Bool
}

struct SessionTimelineModel {
    let time: String
    let caps: String
    let title: String
    let blocks: [SessionBlockRow]
    var before: BeforeCardModel?
    var after: AfterCardModel?
}

struct SessionBlockRow: Identifiable {
    let id = UUID()
    let icon: String
    let name: String
    let detail: String
}

struct FuelScreenModel {
    let overline: String
    let dayStrip: [DayStripModel]
    let load: DayLoadLabel
    let kcalEaten: Int
    let kcalTarget: Int
    let calorieProgress: Double
    let kcalLeft: Int
    let fuelBreakdown: String
    let proteinEaten: Int
    let proteinTarget: Int
    let proteinLeft: Int
    let proteinPercent: Double
    let carbsEaten: Int
    let carbsTarget: Int
    let carbsLeft: Int
    let carbsPercent: Double
    let fatEaten: Int
    let fatTarget: Int
    let fatLeft: Int
    let fatPercent: Double
    let gapTitle: String
    let gapBody: String
    let foods: [FoodRowModel]
    let eatenCount: Int
    let plannedCount: Int
}

struct FoodRowModel: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let protein: Int
    let carbs: Int
    let fat: Int
    let kcal: Int
    let time: String
    let planned: Bool
}

struct PlanScreenModel {
    let overline: String
    let loadSummary: String
    let chartDays: [LoadChartDay]
    let days: [PlanDayModel]
}

struct LoadChartDay: Identifiable {
    var id: String { letter }
    let letter: String
    let load: DayLoadLabel
    let barHeight: CGFloat
    let isToday: Bool
}

struct PlanDayModel: Identifiable {
    var id: Date { date }
    let date: Date
    let day: Int
    let weekdayLabel: String
    let isToday: Bool
    let load: DayLoadLabel
    let title: String
    let chips: [PlanChipStyle]
    let kcal: Int
    let barHeight: CGFloat
}

enum PlanChipStyle {
    case standard(String)
    case ptGuided(String)
}

struct LiveSessionModel {
    let elapsed: String
    let title: String
    let blockProgress: String
    let segmentFill: [Double]
    let exerciseTitle: String
    let exerciseSubtitle: String
    let restLabel: String
    let reps: [LiveRepRowModel]
    let timingPills: [String]
    let selectedTiming: String
    let wind: String
}

enum LiveRepTrailing {
    case meta(String)
    case onTarget
}

enum LiveRepRowModel: Identifiable {
    case done(label: String, value: String, trailing: LiveRepTrailing)
    case active(label: String, partial: String)
    case pending(label: String)

    var id: String {
        switch self {
        case .done(let label, _, _): label
        case .active(let label, _): label
        case .pending(let label): label
        }
    }
}
