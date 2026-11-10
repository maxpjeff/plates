import SwiftUI

/// Yellow/gold = planned for the day; white overlay = eaten (checked off).
struct PlannedMacroBar: View {
    let label: String
    let planned: Double
    let eaten: Double
    let target: Double
    var unit: String = "g"

    private var plannedProgress: Double {
        guard target > 0 else { return 0 }
        return min(1, planned / target)
    }

    private var eatenProgress: Double {
        guard target > 0 else { return 0 }
        return min(1, eaten / target)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(PlatesFont.secondary(12))
                    .foregroundStyle(PlatesColor.muted)
                Spacer()
                Text("\(Int(eaten)) eaten · \(Int(planned)) planned / \(Int(target)) \(unit)")
                    .font(PlatesFont.bodyMedium(12))
                    .foregroundStyle(PlatesColor.ink)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(PlatesColor.soft)
                    Capsule()
                        .fill(PlatesColor.gold.opacity(0.85))
                        .frame(width: geo.size.width * plannedProgress)
                    Capsule()
                        .fill(PlatesColor.eatenBar)
                        .frame(width: geo.size.width * eatenProgress)
                }
            }
            .frame(height: 10)
        }
    }
}

#Preview {
    PlannedMacroBar(label: "Protein", planned: 140, eaten: 84, target: 180)
        .padding()
        .background(PlatesColor.bg)
}
