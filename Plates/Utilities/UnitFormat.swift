import Foundation

enum UnitFormat {
    static func displayWeight(_ kg: Double, units: WeightUnit) -> String {
        switch units {
        case .kg:
            return String(format: "%.1f kg", kg)
        case .lb:
            return String(format: "%.0f lb", kg / 0.453592)
        }
    }

    static func parseWeightInput(_ text: String, units: WeightUnit) -> Double? {
        let cleaned = text.filter { "0123456789.".contains($0) }
        guard let value = Double(cleaned) else { return nil }
        switch units {
        case .kg: return value
        case .lb: return value * 0.453592
        }
    }
}
