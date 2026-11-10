import SwiftUI

struct HeroCard: View {
    let avatarState: AvatarState
    let caption: String

  var body: some View {
        let shape = RoundedRectangle(cornerRadius: 26, style: .continuous)
        VStack(spacing: 0) {
            ZStack(alignment: .bottom) {
                DotGridBackground(base: avatarState.sceneColor, dot: avatarState.sceneDotColor, spacing: 16, dotSize: 1.4)
                AvatarView(state: avatarState)
                    .padding(.bottom, 10)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 262)

            Rectangle()
                .fill(Theme.Color.ink)
                .frame(height: 2.5)

            HStack(alignment: .center, spacing: 12) {
                Text(avatarState.label)
                    .font(CapyFont.fredoka(15))
                    .foregroundStyle(avatarState.pillTextColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(avatarState.pillColor)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(Theme.Color.ink, lineWidth: 2)
                            )
                    )
                Spacer(minLength: 8)
                Text(caption)
                    .font(CapyFont.nunito(14, .heavy))
                    .foregroundStyle(Theme.Color.textSecondary)
                    .multilineTextAlignment(.trailing)
                    .lineLimit(2)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(Theme.Color.card)
        }
        .background(Theme.Color.card)
        .clipShape(shape)
        .background {
            shape
                .fill(Theme.Color.ink)
                .offset(y: 6)
        }
        .overlay {
            shape.strokeBorder(Theme.Color.ink, lineWidth: 2.5)
        }
    }
}

#Preview {
    HeroCard(avatarState: .lockedIn, caption: "Fed 3 hrs ago")
        .padding()
        .background(PaperBackground())
}
