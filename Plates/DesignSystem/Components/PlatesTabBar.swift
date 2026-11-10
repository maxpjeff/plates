import SwiftUI

enum PlatesTab: String, CaseIterable, Identifiable {
    case today, plan, design, progress

    var id: String { rawValue }

    var index: Int {
        Self.allCases.firstIndex(of: self) ?? 0
    }
}

enum PlatesTabMotion {
    static let slide = Animation.easeInOut(duration: 0.33)
}

struct PlatesTabBar: View {
    @Binding var selection: PlatesTab

    var body: some View {
        MainTabBar(selection: $selection)
    }
}
