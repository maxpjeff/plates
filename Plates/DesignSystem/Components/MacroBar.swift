import SwiftUI

struct MacroBar: View {
    let label: String
    let current: Double
    let target: Double
    var fill: Color = PlatesColor.good

    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(1, current / target)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(PlatesFont.secondary(12))
                    .foregroundStyle(PlatesColor.muted)
                Spacer()
                Text("\(Int(current)) / \(Int(target)) g")
                    .font(PlatesFont.bodyMedium(13))
                    .foregroundStyle(PlatesColor.ink)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(PlatesColor.soft)
                    Capsule()
                        .fill(fill)
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 8)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label), \(Int(current)) of \(Int(target)) grams")
    }
}

#Preview {
    MacroBar(label: "Protein", current: 120, target: 180)
        .padding()
        .background(PlatesColor.bg)
}
