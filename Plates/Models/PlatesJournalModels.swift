import Foundation

enum GoalComparator: String, Codable { case under, over }

enum GoalKind: String, Codable { case number, technique }

struct SessionGoal: Identifiable, Codable, Equatable {
    let id: UUID
    var sessionId: UUID
    var blockItemId: UUID?
    var kind: GoalKind
    var label: String
    var comparator: GoalComparator?
    var target: Double?
    var unit: String?
    var text: String?
    var isHit: Bool?
}

enum JournalAttachment: Codable, Equatable {
    case session(UUID)
    case meal(UUID)
    case meet(UUID)
    case day(Date)
}

enum JournalPhase: String, Codable { case before, after }

struct JournalEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var attachedTo: JournalAttachment
    var phase: JournalPhase
    var feel: Int?
    var text: String
    var createdAt: Date
}

struct UserGoal: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var unit: String
    var start: Double
    var current: Double
    var target: Double
    var deadline: Date?
    var note: String?

    var progress: Double { max(0, min(1, (current - start) / (target - start))) }
}

enum PRCategory: String, Codable, CaseIterable {
    case competition, training, lift
}

/// UI / preview model for personal records (maps from `PerformanceRecord` when wired).
struct PersonalRecordRow: Identifiable, Equatable {
    let id: UUID
    let name: String
    let context: String
    let value: String
    let detail: String
    var tagNew: Bool = false
    var tagWindAided: Bool = false
    var valueIsMuted: Bool = false
}
