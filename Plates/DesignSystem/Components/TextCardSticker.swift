import SwiftUI

struct TextCardSticker: View {
    let label: String
    var color: StickerColorName = .wine
    var rotation: Double = -4

    var body: some View {
        Text(label)
            .font(PlatesFont.sectionTitle(18))
            .italic()
            .foregroundStyle(PlatesColor.primaryButtonText)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(PlatesColor.sticker(color))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.9), lineWidth: 4)
            }
            .shadow(color: .black.opacity(0.22), radius: 6, x: 0, y: 3)
            .rotationEffect(.degrees(rotation))
            .accessibilityLabel(label)
    }
}

#Preview {
    TextCardSticker(label: "Pull")
        .padding(40)
        .background(PlatesColor.bg)
}
