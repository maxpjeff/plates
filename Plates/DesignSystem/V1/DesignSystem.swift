import SwiftUI

// MARK: - Color hex

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        switch hex.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255
            g = Double((int >> 8) & 0xFF) / 255
            b = Double(int & 0xFF) / 255
        default:
            r = 0; g = 0; b = 0
        }
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Design tokens

enum DesignSystem {
    enum Color {
        static let bg = SwiftUI.Color(hex: "F2F2F4")
        static let card = SwiftUI.Color(hex: "FFFFFF")
        static let ink = SwiftUI.Color(hex: "111111")
        static let inkSecondary = SwiftUI.Color(hex: "6B6B70")
        static let chipText = SwiftUI.Color(hex: "3A3A3F")
        static let divider = SwiftUI.Color(hex: "EFEFF2")
        static let timelineLine = SwiftUI.Color(hex: "DCDCE0")
        static let nodeEmpty = SwiftUI.Color(hex: "C7C7CC")
        static let checkEmpty = SwiftUI.Color(hex: "D1D1D6")
        static let onDarkSecondary = SwiftUI.Color(hex: "A1A1A6")
        static let darkTile = SwiftUI.Color(hex: "2A2A2E")

        static let accent = SwiftUI.Color(hex: "FF6B1A")
        /// Orange text on light backgrounds (accessible).
        static let accentText = SwiftUI.Color(hex: "C2410C")
        static let accentTint = SwiftUI.Color(hex: "FFF1E8")
        static let accentTintText = SwiftUI.Color(hex: "5A4A40")
        static let ptChipText = SwiftUI.Color(hex: "7A3A12")

        static let macroCarbs = SwiftUI.Color(hex: "F5B700")
        static let macroFat = SwiftUI.Color(hex: "8B5CF6")

        static let sessionBg = SwiftUI.Color(hex: "0B0B0C")
        static let sessionSurface = SwiftUI.Color(hex: "151517")
        static let sessionRow = SwiftUI.Color(hex: "1C1C1F")
        static let sessionRaised = SwiftUI.Color(hex: "2A2A2E")
        static let sessionActiveRow = SwiftUI.Color(hex: "1F1A17")
        static let sessionMuted = SwiftUI.Color(hex: "5A5A60")
        static let sessionDim = SwiftUI.Color(hex: "8E8E93")
        static let sessionPillText = SwiftUI.Color(hex: "D1D1D6")
    }

    enum Layout {
        static let screenPadding: CGFloat = 20
        /// Extra scroll padding above the tab chrome (`safeAreaInset` handles the bar).
        static let scrollBottomPadding: CGFloat = 20
        static let tabBarSideInset: CGFloat = 20
        /// Space from home indicator to tab bar (tab sits lower in the safe area).
        static let tabBarBottomInset: CGFloat = 8
        /// Opaque chrome under the floating bar (blocks scroll bleed).
        static let tabBarChromeExtra: CGFloat = 10
        static let tabBarHeight: CGFloat = 68
        static let sectionGapToday: CGFloat = 18
        static let sectionGapProgress: CGFloat = 16
        /// Today timeline clearance above floating tab bar.
        static let todayScrollBottomPadding: CGFloat = 120
        static let sectionGapFuel: CGFloat = 16
        static let sectionGapPlan: CGFloat = 14
        static let sectionGapSession: CGFloat = 14
    }

    enum Radius {
        static let summary: CGFloat = 24
        static let sessionBlock: CGFloat = 22
        static let meal: CGFloat = 20
        static let saveRep: CGFloat = 18
        static let button: CGFloat = 16
        static let foodIcon: CGFloat = 14
        static let sessionIconTile: CGFloat = 10
        static let dayPill: CGFloat = 16
    }
}

extension DayLoadLabel {
    var fillColor: Color {
        switch self {
        case .high: Color(hex: "1D4ED8")
        case .moderate: Color(hex: "60A5FA")
        case .low: Color(hex: "BFDBFE")
        case .rest: Color(hex: "E5E5EA")
        }
    }

    var textColor: Color {
        switch self {
        case .high: .white
        case .moderate, .low: Color(hex: "0B1B3F")
        case .rest: DesignSystem.Color.chipText
        }
    }

    var stripDotColor: Color {
        switch self {
        case .high: Color(hex: "1D4ED8")
        case .moderate: Color(hex: "60A5FA")
        case .low: Color(hex: "BFDBFE")
        case .rest: DesignSystem.Color.checkEmpty
        }
    }

    var badgeTitle: String { title }

    var headerBadgeTitle: String { "\(title) day" }
}

// MARK: - Inter typography

enum InterFont {
    static func inter(_ size: CGFloat, _ weight: Font.Weight) -> Font {
        .custom(postScriptName(for: weight), size: size)
    }

    private static func postScriptName(for weight: Font.Weight) -> String {
        switch weight {
        case .medium: "Inter-Medium"
        case .semibold: "Inter-SemiBold"
        case .bold: "Inter-Bold"
        case .heavy: "Inter-ExtraBold"
        default: "Inter-Regular"
        }
    }
}

enum PlatesFormat {
    static func grouped(_ value: Int) -> String {
        value.formatted(.number.grouping(.automatic))
    }
}
