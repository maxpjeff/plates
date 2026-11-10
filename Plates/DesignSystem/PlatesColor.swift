import SwiftUI

enum PlatesColor {
    static let bg = Color("bg")
    static let surface = Color("surface")
    static let card = Color("card")
    static let soft = Color("soft")
    static let ink = Color("ink")
    static let muted = Color("muted")
    static let line = Color("line")
    static let divider = Color("divider")
    static let primaryButton = Color("primaryButton")
    static let primaryButtonText = Color("primaryButtonText")
    static let accent = Color("accent")
    static let good = Color("good")
    static let gold = Color("gold")
    static let heart = Color("heart")
    static let carbsMacro = Color("carbsMacro")
    static let fatMacro = Color("fatMacro")
    static let stickerSand = Color("stickerSand")
    /// Eaten progress overlay on macro bars (light/dark aware).
    static let eatenBar = Color("eatenBar")

    static func sticker(_ name: StickerColorName) -> Color {
        switch name {
        case .olive: Color(hex: 0x4B5A3C)
        case .wine: Color(hex: 0x6E1F2B)
        case .navy: Color(hex: 0x24324A)
        case .espresso: Color(hex: 0x4A3326)
        case .gold: PlatesColor.gold
        case .sand: PlatesColor.stickerSand
        }
    }
}

enum StickerColorName: String, Codable, CaseIterable {
    case olive, wine, navy, espresso, gold, sand
}

private extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
