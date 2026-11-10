import SwiftUI

/// Cream-paper surfaces always use ink text (avoids white Form / adaptive labels in dark mode).
enum CapyTextStyles {
    static func bodyInk() -> some ViewModifier {
        CapyInkModifier()
    }
}

private struct CapyInkModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundStyle(Theme.Color.ink)
            .tint(Theme.Color.orange)
    }
}

extension View {
    func capyPaperText() -> some View {
        modifier(CapyInkModifier())
    }
}

struct CapyTextFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(CapyFont.nunito(18, .bold))
            .foregroundStyle(Theme.Color.ink)
            .tint(Theme.Color.orange)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Theme.Color.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Theme.Color.ink, lineWidth: 2)
                    )
            )
    }
}

extension View {
    func capyTextFieldChrome() -> some View {
        modifier(CapyTextFieldStyle())
    }
}

struct CapySymbol: View {
    let systemName: String
    var size: CGFloat = 18
    var color: Color = Theme.Color.ink

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size, weight: .semibold))
            .symbolRenderingMode(.monochrome)
            .foregroundStyle(color)
    }
}
