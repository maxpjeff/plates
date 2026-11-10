import SwiftUI

struct FedView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(CapyAppState.self) private var appState

    let name: String
    let image: UIImage
    let streakDay: Int
    let newStreak: Bool

    var body: some View {
        ZStack {
            PaperBackground()
            Sunburst()
            VStack(spacing: 20) {
                PolaroidFrame(rotation: -4) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 220, height: 220)
                        .clipped()
                }
                .overlay(alignment: .top) {
                    TapeStrip().offset(y: -12)
                }
                VStack(spacing: 4) {
                    Text(timestamp)
                        .font(CapyFont.nunito(13, .heavy))
                    Text("Day \(streakDay)")
                        .font(CapyFont.fredoka(20))
                }
                AvatarView(state: .lockedIn)
                    .frame(width: 120, height: 100)
                Text("\(name) is fed!")
                    .font(CapyFont.fredoka(30))
                Text(subtitle)
                    .font(CapyFont.nunito(16))
                    .foregroundStyle(Theme.Color.textSecondary)
                    .multilineTextAlignment(.center)
                HStack(spacing: 12) {
                    statCard(title: "Streak", value: "\(streakDay) days", fill: Theme.Color.yellowSoft)
                    statCard(title: "Energy", value: "Full", fill: Theme.Color.greenSoft)
                }
                .padding(.horizontal, 24)
                CapyPrimaryButton(title: "Done") {
                    appState.showFed = false
                    dismiss()
                }
                .padding(.horizontal, 24)
            }
            .padding(.vertical, 32)
        }
        .onAppear {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    private var subtitle: String {
        if newStreak { return "Day 1. New streak started." }
        return "Back in action. See you within 48 hours."
    }

    private var timestamp: String {
        let f = DateFormatter()
        f.dateFormat = "E h:mm a"
        return f.string(from: Date())
    }

    private func statCard(title: String, value: String, fill: Color) -> some View {
        VStack(spacing: 6) {
            Text(title).font(CapyFont.nunito(13, .heavy))
            Text(value).font(CapyFont.fredoka(22))
        }
        .foregroundStyle(Theme.Color.ink)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(fill)
                .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Theme.Color.ink, lineWidth: 2))
        )
    }
}

private struct Sunburst: View {
    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 3)
            ForEach(0..<12, id: \.self) { i in
                Rectangle()
                    .fill(Theme.Color.yellowSoft.opacity(0.35))
                    .frame(width: 8, height: geo.size.height)
                    .position(center)
                    .rotationEffect(.degrees(Double(i) * 30))
            }
        }
        .allowsHitTesting(false)
    }
}

private struct TapeStrip: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Color.white.opacity(0.55))
            .frame(width: 60, height: 18)
            .rotationEffect(.degrees(-8))
    }
}

#Preview {
    FedView(name: "Biscuit", image: UIImage(systemName: "photo")!, streakDay: 13, newStreak: false)
        .environment(CapyAppState())
}
