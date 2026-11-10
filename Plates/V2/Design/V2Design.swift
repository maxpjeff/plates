import SwiftUI

extension Color {
    init(v2Hex: String) {
        let hex = v2Hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

enum V2Color {
    static let bg = Color(v2Hex: "F5F2ED")
    static let card = Color(v2Hex: "FFFDFA")
    static let line = Color(v2Hex: "E8E2D9")
    static let track = Color(v2Hex: "EDE7DE")
    static let dish = Color(v2Hex: "F3EEE6")
    static let dishLine = Color(v2Hex: "DCD3C6")
    static let ink = Color(v2Hex: "33302C")
    static let sec = Color(v2Hex: "6B655E")
    static let ter = Color(v2Hex: "7D776F")
    static let accent = Color(v2Hex: "E8B49A")
    static let accentDeep = Color(v2Hex: "D9896A")
    static let accentTint = Color(v2Hex: "FBECE3")
    static let met = Color(v2Hex: "8FAF88")
    static let chip = Color(v2Hex: "E3ECDD")
    static let effortHard = Color(v2Hex: "FBE2D5")
    static let effortMedium = Color(v2Hex: "F3E8D2")
    static let effortLight = Color(v2Hex: "E3ECDD")
    static let sageLine = Color(v2Hex: "BFD0B6")
    static let sageTint = Color(v2Hex: "F1F5EE")
}

enum V2Font {
    static func serif(_ size: CGFloat) -> Font {
        .custom("InstrumentSerif-Regular", size: size)
    }

    static func inter(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .custom(interName(for: weight), size: size)
    }

    private static func interName(for weight: Font.Weight) -> String {
        switch weight {
        case .medium: "Inter-Medium"
        case .semibold: "Inter-SemiBold"
        case .bold: "Inter-Bold"
        case .heavy: "Inter-ExtraBold"
        default: "Inter-Regular"
        }
    }
}

enum V2Layout {
    static let screenHPadding: CGFloat = 16
    static let topPadding: CGFloat = 54
    static let bottomBarInset: CGFloat = 22
    static let mealTileSize: CGFloat = 84
    static let mealTileSpacing: CGFloat = 10
    static let mealRailHeight: CGFloat = 94
    static let roundButton: CGFloat = 42
}
