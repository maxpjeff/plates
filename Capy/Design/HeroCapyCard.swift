import SwiftUI

struct HeroCapyCard: View {
    let phase: CapyMascotPhase
    let engineState: CapyState
    let caption: String
    var heroHeight: CGFloat = 200

    private var stageColor: Color {
        switch phase {
        case .lockedIn: Theme.Color.greenSoft
        case .recovering: Theme.Color.yellowSoft
        case .couch: Theme.Color.lilacSoft
        case .streakLost: Color(capyHex: "F5D4D4")
        }
    }

    private var stageDots: Color {
        switch phase {
        case .lockedIn: Color(capyHex: "B8E5A0")
        case .recovering: Color(capyHex: "F0C878")
        case .couch: Color(capyHex: "C8B8E8")
        case .streakLost: Color(capyHex: "E8B8B8")
        }
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Theme.Layout.cardRadius, style: .continuous)
        VStack(spacing: 0) {
            ZStack {
                DotGridBackground(base: stageColor, dot: stageDots)
                MascotView(phase: phase, size: heroHeight - 20, style: .hero)
            }
            .frame(maxWidth: .infinity)
            .frame(height: heroHeight)

            HStack(alignment: .center, spacing: 12) {
                StatusPill(state: engineState)
                Spacer(minLength: 8)
                Text(caption)
                    .font(CapyFont.nunito(14, .heavy))
                    .foregroundStyle(Theme.Color.textSecondary)
                    .multilineTextAlignment(.trailing)
                    .lineLimit(2)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(Theme.Color.card)
        }
        .clipShape(shape)
        .background {
            HardShadowFill(shape: shape, fill: Theme.Color.card)
        }
    }
}
