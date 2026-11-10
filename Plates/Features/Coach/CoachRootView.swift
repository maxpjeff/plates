import SwiftUI

struct CoachRootView: View {
    var body: some View {
        ContentUnavailableView(
            "Coach",
            systemImage: "lock.fill",
            description: Text("Premium Coach tier comes in a later phase.")
        )
        .background(PlatesColor.bg)
    }
}

#Preview {
    CoachRootView()
}
