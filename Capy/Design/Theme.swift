import SwiftUI

// TODO: replace with final capybara art (MascotView only)

extension Color {
    init(capyHex: String) {
        let hex = capyHex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

enum Theme {
    enum Color {
        static let ink = SwiftUI.Color(capyHex: "2B2118")
        static let paper = SwiftUI.Color(capyHex: "FFF4E2")
        static let paperDot = SwiftUI.Color(capyHex: "EBD6B5")
        static let card = SwiftUI.Color(capyHex: "FFFDF8")
        static let textSecondary = SwiftUI.Color(capyHex: "6B5741")
        static let orange = SwiftUI.Color(capyHex: "FF9F43")
        static let orangeSoft = SwiftUI.Color(capyHex: "FFB84D")
        static let flame = SwiftUI.Color(capyHex: "FF7A2F")
        static let yellowSoft = SwiftUI.Color(capyHex: "FFD08A")
        static let green = SwiftUI.Color(capyHex: "7BC043")
        static let greenSoft = SwiftUI.Color(capyHex: "CFEFB4")
        static let greenText = SwiftUI.Color(capyHex: "1F4A0B")
        static let lilacSoft = SwiftUI.Color(capyHex: "E3DAF2")
        static let blueSoft = SwiftUI.Color(capyHex: "CDE8F7")
        static let blueText = SwiftUI.Color(capyHex: "0D3B5C")
        static let restOutline = SwiftUI.Color(capyHex: "A8957A")
        static let cameraBg = SwiftUI.Color(capyHex: "1E1712")
        static let asleepGray = SwiftUI.Color(capyHex: "8A9AAB")
    }

    enum Font {
        static func fredoka(_ size: CGFloat, rounded: Bool = true) -> SwiftUI.Font {
            let name = rounded ? CapyFontResolver.fredokaBold : CapyFontResolver.fredokaSemiBold
            return .custom(name, size: size, relativeTo: .title)
        }

        static func nunito(_ size: CGFloat, weight: SwiftUI.Font.Weight = .bold) -> SwiftUI.Font {
            let name: String = switch weight {
            case .heavy, .black: CapyFontResolver.nunitoExtraBold
            case .bold: CapyFontResolver.nunitoBold
            default: CapyFontResolver.nunitoSemiBold
            }
            return .custom(name, size: size, relativeTo: .body)
        }
    }

    enum Layout {
        static let cardRadius: CGFloat = 26
        static let border: CGFloat = 2.5
        static let hardShadow: CGFloat = 6
        static let primaryButtonHeight: CGFloat = 64
    }
}

enum CapyFont {
    static func fredoka(_ size: CGFloat) -> Font { Theme.Font.fredoka(size) }
    static func nunito(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font { Theme.Font.nunito(size, weight: weight) }
}
