import SwiftUI

/// Layout tokens aligned to Plates app mockups (Nov 2026).
enum MockupLayout {
    static let screenPadding: CGFloat = 20
    static let sectionSpacing: CGFloat = 24
    static let rowSpacing: CGFloat = 16
    static let cardRadius: CGFloat = 16
    static let heroKcalSize: CGFloat = 52
    static let tabBarHeight: CGFloat = 56
}

struct MockupScreenTitle: View {
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let subtitle {
                Text(subtitle)
                    .font(PlatesFont.secondary(13))
                    .foregroundStyle(PlatesColor.muted)
            }
            Text(title)
                .font(PlatesFont.screenTitle(36))
                .foregroundStyle(PlatesColor.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct MockupDateHeader: View {
    let selectedDate: Date

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(selectedDate.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                    .font(PlatesFont.secondary(14))
                    .foregroundStyle(PlatesColor.muted)
                Text("Today")
                    .font(PlatesFont.screenTitle(34))
            }
            Spacer()
        }
    }
}
