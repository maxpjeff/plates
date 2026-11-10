import SwiftUI

struct MealSticker: View {
    var tint: Color = PlatesColor.accent
    var size: CGFloat = 52

    var body: some View {
        ZStack {
            Circle()
                .fill(tint.opacity(0.25))
            Image(systemName: "fork.knife.circle.fill")
                .font(.system(size: size * 0.55))
                .foregroundStyle(tint)
        }
        .frame(width: size, height: size)
        .overlay {
            Circle()
                .strokeBorder(Color.white, lineWidth: 3)
        }
        .shadow(color: .black.opacity(0.18), radius: 5, x: 0, y: 2)
        .accessibilityHidden(true)
    }
}

#Preview {
    MealSticker()
        .padding()
        .background(PlatesColor.bg)
}
