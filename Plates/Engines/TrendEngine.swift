import Foundation

enum TrendEngine {
    /// Exponentially weighted moving average, alpha = 0.1. Missing days skipped.
    static func trendValues(entries: [(date: Date, weightKg: Double)], alpha: Double = 0.1) -> [(date: Date, trendKg: Double)] {
        let sorted = entries.sorted { $0.date < $1.date }
        guard var lastTrend = sorted.first?.weightKg else { return [] }
        var out: [(Date, Double)] = []
        for entry in sorted {
            lastTrend = alpha * entry.weightKg + (1 - alpha) * lastTrend
            out.append((entry.date, lastTrend))
        }
        return out
    }

    static func trendToday(entries: [(date: Date, weightKg: Double)]) -> Double? {
        trendValues(entries: entries).last?.trendKg
    }

    static func weeklyRateKg(entries: [(date: Date, weightKg: Double)]) -> Double? {
        let trends = trendValues(entries: entries)
        guard trends.count >= 2,
              let last = trends.last,
              let weekAgo = trends.dropLast(7).last ?? trends.first
        else { return nil }
        return last.trendKg - weekAgo.trendKg
    }
}
