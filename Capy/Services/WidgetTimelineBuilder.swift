import Foundation

struct CapyTimelineEntry: Equatable {
    var date: Date
    var snapshot: WidgetSnapshot
}

enum WidgetTimelineBuilder {
    /// Now plus the next three midnights (status changes at midnight and on post via reload).
    static func entries(for snapshot: WidgetSnapshot, from start: Date = CapyClock.now()) -> [CapyTimelineEntry] {
        let cal = Calendar.current
        var dates = [start]
        let today = cal.startOfDay(for: start)
        for day in 1...3 {
            if let midnight = cal.date(byAdding: .day, value: day, to: today) {
                dates.append(midnight)
            }
        }
        return dates.map { CapyTimelineEntry(date: $0, snapshot: snapshot) }
    }
}
