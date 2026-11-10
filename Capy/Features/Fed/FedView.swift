import SwiftUI

struct FedView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(CapyAppState.self) private var appState

    let name: String
    let image: UIImage
    let streakDay: Int
    let newStreak: Bool
    let settings: CapySettings

    var body: some View {
        PxFedView(model: model) {
            appState.showFed = false
            dismiss()
        }
    }

    private var model: PxFedModel {
        let f = DateFormatter()
        f.dateFormat = "EEE h:mm a"
        return PxFedModel(
            name: name,
            photo: Image(uiImage: image),
            timeText: f.string(from: Date()),
            dayNumber: streakDay,
            subtitle: PxModelBuilder.fedSubtitle(newStreak: newStreak, settings: settings),
            streak: streakDay
        )
    }
}
