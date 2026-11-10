import SwiftUI

enum AppThemeMode: String, CaseIterable {
    case light
    case dark

    var colorScheme: ColorScheme {
        switch self {
        case .light: .light
        case .dark: .dark
        }
    }

    var toggleIcon: String {
        switch self {
        case .light: "moon.fill"
        case .dark: "sun.max.fill"
        }
    }
}

@MainActor
final class AppAppearance: ObservableObject {
    static let shared = AppAppearance()

    @Published var mode: AppThemeMode {
        didSet { UserDefaults.standard.set(mode.rawValue, forKey: Self.storageKey) }
    }

    private static let storageKey = "plates.themeMode"

    private init() {
        if let raw = UserDefaults.standard.string(forKey: Self.storageKey),
           let saved = AppThemeMode(rawValue: raw) {
            mode = saved
        } else {
            mode = .light
        }
    }

    func toggle() {
        mode = mode == .light ? .dark : .light
    }
}

struct ThemeToggleButton: View {
    @EnvironmentObject private var appearance: AppAppearance

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                appearance.toggle()
            }
        } label: {
            Image(systemName: appearance.mode.toggleIcon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(PlatesColor.ink)
                .frame(width: 40, height: 40)
                .background(.ultraThinMaterial, in: Circle())
                .overlay(Circle().strokeBorder(PlatesColor.line.opacity(0.6), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(appearance.mode == .light ? "Switch to dark mode" : "Switch to light mode")
    }
}
