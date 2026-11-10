import SwiftUI

enum PlatesCardStyle {
    case standard
    case elevated
    case inset
}

struct PlatesCard<Content: View>: View {
    var padding: CGFloat = 16
    var style: PlatesCardStyle = .standard
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                if style == .standard {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(PlatesColor.line.opacity(0.65), lineWidth: 1)
                }
            }
            .shadow(color: shadowColor, radius: shadowRadius, y: shadowY)
    }

    private var cornerRadius: CGFloat {
        switch style {
        case .elevated: 22
        case .inset, .standard: 18
        }
    }

    @ViewBuilder
    private var background: some View {
        switch style {
        case .standard, .elevated:
            PlatesColor.surface
        case .inset:
            PlatesColor.soft.opacity(0.45)
        }
    }

    private var shadowColor: Color {
        style == .elevated ? PlatesColor.ink.opacity(0.06) : .clear
    }

    private var shadowRadius: CGFloat {
        style == .elevated ? 16 : 0
    }

    private var shadowY: CGFloat {
        style == .elevated ? 8 : 0
    }
}

#Preview {
    VStack(spacing: 16) {
        PlatesCard { Text("Standard") }
        PlatesCard(style: .elevated) { Text("Elevated") }
        PlatesCard(style: .inset) { Text("Inset") }
    }
    .padding()
    .background(PlatesColor.bg)
}
