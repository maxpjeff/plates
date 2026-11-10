import SwiftUI

struct WorkoutFinishView: View {
    let duration: TimeInterval
    let setCount: Int
    let prCount: Int
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text("Workout saved")
                .font(PlatesFont.sectionTitle(28))
            PlatesCard {
                VStack(alignment: .leading, spacing: 8) {
                    row("Duration", value: formatElapsed(duration))
                    row("Sets logged", value: "\(setCount)")
                    row("PRs", value: "\(prCount)")
                }
            }
            Button(action: onDone) {
                Text("Done")
                    .font(PlatesFont.bodySemibold())
                    .foregroundStyle(PlatesColor.primaryButtonText)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(PlatesColor.primaryButton)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(24)
        .presentationDetents([.medium])
        .background(PlatesColor.bg)
    }

    private func row(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(PlatesColor.muted)
            Spacer()
            Text(value)
                .font(PlatesFont.bodySemibold())
        }
    }

    private func formatElapsed(_ interval: TimeInterval) -> String {
        let m = Int(interval) / 60
        let s = Int(interval) % 60
        return String(format: "%d min %d sec", m, s)
    }
}
