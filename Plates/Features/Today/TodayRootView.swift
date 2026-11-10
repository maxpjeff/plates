import SwiftUI
import SwiftData

/// Legacy entry; primary experience lives on `HomeRootView`.
struct TodayRootView: View {
    var body: some View {
        ScrollView {
            TodayDashboardSections()
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
        }
        .background(PlatesColor.bg)
    }
}

#Preview {
    TodayRootView()
        .modelContainer(SampleData.previewContainer())
}
