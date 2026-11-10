import Foundation
import SwiftData

@MainActor
enum HybridDataStore {
    static func session(for date: Date, context: ModelContext) -> TrainingSession? {
        let start = Calendar.current.startOfDay(for: date)
        let sessions = (try? context.fetch(FetchDescriptor<TrainingSession>())) ?? []
        return sessions
            .filter { !$0.isTemplate }
            .first { Calendar.current.isDate($0.dayDate, inSameDayAs: start) }
    }

    static func templates(context: ModelContext) -> [TrainingSession] {
        let sessions = (try? context.fetch(FetchDescriptor<TrainingSession>())) ?? []
        return sessions.filter(\.isTemplate).sorted { $0.title < $1.title }
    }

    static func dayLoad(for date: Date, context: ModelContext, planned: Bool = true) -> DayLoadSnapshot? {
        guard let session = session(for: date, context: context) else { return nil }
        let profile = PlatesDataStore.profile(context: context)
        let inputs = blockInputs(for: session, bodyWeightKg: profile.resolvedBodyWeightKg, useActual: !planned)
        guard !inputs.isEmpty else { return nil }
        return DayLoadEngine.dayLoad(date: date, blocks: inputs, isPlanned: planned)
    }

    static func blockInputs(
        for session: TrainingSession,
        bodyWeightKg: Double,
        useActual: Bool
    ) -> [DayLoadEngine.BlockLoadInput] {
        session.blocks.sorted { $0.order < $1.order }.flatMap { block in
            block.items.sorted { $0.order < $1.order }.compactMap { item -> DayLoadEngine.BlockLoadInput? in
                guard let spec = item.plannedSpec else { return nil }
                return DayLoadEngine.BlockLoadInput(
                    type: block.blockType,
                    spec: spec,
                    result: useActual ? item.actualResult : nil,
                    durationMinutes: Double(block.estimatedMinutes),
                    bodyWeightKg: bodyWeightKg
                )
            }
        }
    }

    static func pr(forEventCode eventCode: String, context: ModelContext) -> PerformanceRecord? {
        let events = (try? context.fetch(FetchDescriptor<TrackEvent>())) ?? []
        guard let event = events.first(where: { $0.code == eventCode }) else { return nil }
        let records = (try? context.fetch(FetchDescriptor<PerformanceRecord>())) ?? []
        return records
            .filter { $0.event?.id == event.id && $0.isWindLegal }
            .min(by: { $0.value < $1.value })
    }

    static func targetSprintTime(distanceM: Double, intensityPct: Int, context: ModelContext) -> Double? {
        let code = "fly_\(Int(distanceM))m"
        guard let pr = pr(forEventCode: code, context: context) else { return nil }
        return pr.value * (100.0 / Double(intensityPct))
    }
}
