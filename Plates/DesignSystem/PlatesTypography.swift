import SwiftUI
import UIKit

enum PlatesFont {
    private static let serifRegular = "InstrumentSerif-Regular"
    private static let serifItalic = "InstrumentSerif-Italic"
    private static let sansRegular = "Manrope-Regular"
    private static let sansMedium = "Manrope-Medium"
    private static let sansSemiBold = "Manrope-SemiBold"
    private static let sansBold = "Manrope-Bold"

    static func screenTitle(_ size: CGFloat = 44) -> Font {
        customOrSerif(serifRegular, size: size, relativeTo: .largeTitle)
    }

    static func screenTitleItalic(_ size: CGFloat = 44) -> Font {
        customOrSerif(serifItalic, size: size, relativeTo: .largeTitle).italic()
    }

    static func sectionTitle(_ size: CGFloat = 24) -> Font {
        customOrSans(sansSemiBold, size: size, relativeTo: .title2)
    }

    static func statHero(_ size: CGFloat = 40) -> Font {
        customOrSans(sansBold, size: size, relativeTo: .largeTitle)
    }

    static func statLabel(_ size: CGFloat = 13) -> Font {
        customOrSans(sansSemiBold, size: size, relativeTo: .subheadline)
    }

    static func bigNumber(_ size: CGFloat = 32) -> Font {
        customOrSans(sansBold, size: size, relativeTo: .title)
    }

    static func body(_ size: CGFloat = 15) -> Font {
        customOrSans(sansRegular, size: size, relativeTo: .body)
    }

    static func bodyMedium(_ size: CGFloat = 15) -> Font {
        customOrSans(sansMedium, size: size, relativeTo: .body)
    }

    static func bodySemibold(_ size: CGFloat = 15) -> Font {
        customOrSans(sansSemiBold, size: size, relativeTo: .body)
    }

    static func secondary(_ size: CGFloat = 13) -> Font {
        customOrSans(sansRegular, size: size, relativeTo: .subheadline)
    }

    static func labelCaps(_ size: CGFloat = 11) -> Font {
        customOrSans(sansBold, size: size, relativeTo: .caption2)
    }

    private static func customOrSerif(_ name: String, size: CGFloat, relativeTo style: Font.TextStyle) -> Font {
        if UIFont(name: name, size: size) != nil {
            return .custom(name, size: size, relativeTo: style)
        }
        return .system(size: size, weight: .regular, design: .serif)
    }

    private static func customOrSans(_ name: String, size: CGFloat, relativeTo style: Font.TextStyle) -> Font {
        if UIFont(name: name, size: size) != nil {
            return .custom(name, size: size, relativeTo: style)
        }
        return .system(size: size, weight: weight(for: name), design: .default)
    }

    private static func weight(for name: String) -> Font.Weight {
        if name.contains("Bold") { return .bold }
        if name.contains("SemiBold") { return .semibold }
        if name.contains("Medium") { return .medium }
        return .regular
    }
}

struct PlatesLabelCaps: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(PlatesFont.labelCaps())
            .tracking(1.2)
            .textCase(.uppercase)
            .foregroundStyle(PlatesColor.muted)
    }
}

extension View {
    func platesLabelCaps() -> some View {
        modifier(PlatesLabelCaps())
    }
}
