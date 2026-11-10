import SwiftUI

struct WorkoutEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var store: FuelStore
    let weekday: Int

    @State private var workout: String = ""
    @State private var effort: Effort = .medium

    private let suggestions = [
        "Push", "Pull", "Legs", "Upper", "Lower", "Full body",
        "Sprints", "Plyos", "Long run", "Tempo run", "Speed work", "Easy run", "Sport practice", "Rest",
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(weekdayTitle)
                .font(V2Font.serif(30))
                .foregroundStyle(V2Color.ink)

            Text("Workout")
                .font(V2Font.inter(13, .semibold))
                .foregroundStyle(V2Color.sec)
            TextField("Workout", text: $workout)
                .font(V2Font.inter(16, .medium))
                .padding(.horizontal, 14)
                .frame(height: 50)
                .v2Card(radius: 16)

            FlowLayoutV2(spacing: 8) {
                ForEach(suggestions, id: \.self) { chip in
                    Button {
                        workout = chip
                        if chip == "Rest" { effort = .medium }
                    } label: {
                        Text(chip)
                            .font(V2Font.inter(12, .semibold))
                            .foregroundStyle(workout == chip ? Color.white : V2Color.ink)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(workout == chip ? V2Color.ink : V2Color.card)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(V2Color.line, lineWidth: workout == chip ? 0 : 1))
                    }
                    .buttonStyle(.plain)
                }
            }

            if workout != "Rest" {
                Text("How hard is it?")
                    .font(V2Font.inter(13, .semibold))
                    .foregroundStyle(V2Color.sec)
                HStack(spacing: 8) {
                    effortButton(.light, subtitle: "fewer carbs")
                    effortButton(.medium, subtitle: "standard")
                    effortButton(.hard, subtitle: "more carbs")
                }
            }

            HStack {
                Text("That day's targets")
                    .font(V2Font.inter(13, .semibold))
                    .foregroundStyle(V2Color.sec)
                Spacer()
                Text(previewTargets)
                    .font(V2Font.inter(13, .bold))
                    .foregroundStyle(V2Color.ink)
            }

            Button(action: save) {
                Text("Save \(weekdayTitle)")
                    .font(V2Font.inter(16, .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(V2Color.ink)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(V2Color.bg)
        .onAppear {
            let split = store.split.first { $0.weekday == weekday }
            workout = split?.workout ?? ""
            effort = split?.effort ?? .medium
        }
    }

    private var weekdayTitle: String {
        ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"][weekday - 1]
    }

    private var previewTargets: String {
        let split = SplitDay(weekday: weekday, workout: workout.isEmpty ? "Rest" : workout, effort: workout == "Rest" ? nil : effort)
        let t = TargetCalculator.targets(for: split, settings: store.settings)
        return "\(t.kcal.formatted(.number.grouping(.automatic))) kcal · \(t.carbs)g carbs · \(t.protein)g protein"
    }

    private func effortButton(_ value: Effort, subtitle: String) -> some View {
        Button {
            effort = value
        } label: {
            VStack(spacing: 4) {
                Text(value.rawValue)
                    .font(V2Font.inter(14, .bold))
                Text(subtitle)
                    .font(V2Font.inter(11, .medium))
            }
            .foregroundStyle(V2Color.ink)
            .frame(maxWidth: .infinity, minHeight: 64)
            .background(effortFill(value))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                if effort == value {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(V2Color.ink, lineWidth: 2)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func effortFill(_ value: Effort) -> Color {
        switch value {
        case .light: V2Color.effortLight
        case .medium: V2Color.effortMedium
        case .hard: V2Color.effortHard
        }
    }

    private func save() {
        var day = SplitDay(weekday: weekday, workout: workout.isEmpty ? "Rest" : workout, effort: workout == "Rest" ? nil : effort)
        if day.workout != "Rest" && day.effort == nil { day.effort = .medium }
        store.updateSplitDay(day)
        dismiss()
    }
}

struct FlowLayoutV2: Layout {
    var spacing: CGFloat = 8
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        layout(proposal: proposal, subviews: subviews).size
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY), proposal: .unspecified)
        }
    }
    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        let width = proposal.width ?? 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var frames: [CGRect] = []
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            frames.append(CGRect(x: x, y: y, width: size.width, height: size.height))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
        return (CGSize(width: width, height: y + rowHeight), frames)
    }
}
