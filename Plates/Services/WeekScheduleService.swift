import Foundation
import SwiftData

@MainActor
enum WeekScheduleService {
    static func schedule(for weekday: Int, context: ModelContext) -> WeekSchedule? {
        let schedules = (try? context.fetch(FetchDescriptor<WeekSchedule>())) ?? []
        return schedules.first { $0.weekday == weekday }
    }

    static func routine(for weekday: Int, context: ModelContext) -> Routine? {
        guard let s = schedule(for: weekday, context: context), !s.isRest else { return nil }
        return s.routine
    }

    static func assign(routine: Routine?, to weekday: Int, workoutTime: Date?, context: ModelContext) {
        if let existing = schedule(for: weekday, context: context) {
            existing.routine = routine
            existing.isRest = routine == nil
            existing.preferredWorkoutTime = workoutTime
            return
        }
        context.insert(
            WeekSchedule(
                weekday: weekday,
                routine: routine,
                isRest: routine == nil,
                preferredWorkoutTime: workoutTime
            )
        )
    }

    static func markRest(weekday: Int, context: ModelContext) {
        assign(routine: nil, to: weekday, workoutTime: nil, context: context)
        if let s = schedule(for: weekday, context: context) {
            s.isRest = true
        }
    }
}
