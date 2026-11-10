import SwiftUI

/// Preview-only gallery for Phase 0 design system QA.
struct DesignGalleryView: View {
    @State private var segment = 0
    @State private var tab: PlatesTab = .today

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Design gallery")
                    .font(PlatesFont.screenTitle(36))
                TextCardSticker(label: "Pull", color: .olive)
                MealSticker()
                SegmentedTabs(options: [0, 1], selection: $segment, title: { $0 == 0 ? "One" : "Two" })
                HStack {
                    PillChip(title: "Selected", isSelected: true)
                    PillChip(title: "Chip")
                }
                MacroBar(label: "Protein", current: 140, target: 180)
                MacroBar(label: "Calories", current: 1800, target: 2400, fill: PlatesColor.ink)
                PlatesCard {
                    Text("PlatesCard on surface with line border.")
                        .font(PlatesFont.body())
                }
                PlatesTabBar(selection: $tab)
            }
            .padding(20)
        }
        .background(PlatesColor.bg)
    }
}

#Preview("Design gallery — light") {
    DesignGalleryView()
        .preferredColorScheme(.light)
}

#Preview("Design gallery — dark") {
    DesignGalleryView()
        .preferredColorScheme(.dark)
}
