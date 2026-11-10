import SwiftData
import SwiftUI

struct HistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \Feed.takenAt, order: .reverse) private var feeds: [Feed]
    @Query private var capys: [Capybara]
    @Query private var settingsList: [CapySettings]

    @State private var monthAnchor = Date()
    @State private var selectedFeed: Feed?

    var body: some View {
        Group {
            if let capy = capys.first, let settings = settingsList.first {
                let snap = SharedStore.snapshot(capy: capy, settings: settings, feeds: feeds)
                let cal = Calendar.current
                let feedsInMonth = feeds.filter {
                    cal.isDate($0.takenAt, equalTo: monthAnchor, toGranularity: .month)
                }
                let model = PxModelBuilder.historyModel(
                    capy: capy,
                    snap: snap,
                    monthAnchor: monthAnchor,
                    feedsInMonth: feedsInMonth,
                    allFeeds: feeds,
                    settings: settings,
                    at: Date()
                )
                PxHistoryView(
                    model: model,
                    onBack: { dismiss() },
                    onPreviousMonth: { shiftMonth(-1) },
                    onNextMonth: { shiftMonth(1) },
                    onSelectFeed: { index in
                        if index < feeds.count {
                            selectedFeed = feeds[index]
                        }
                    }
                )
            }
        }
        .sheet(item: $selectedFeed) { feed in
            FeedDetailSheet(feed: feed) {
                PhotoStore.delete(filename: feed.photoFilename)
                context.delete(feed)
                try? context.save()
                WidgetReloader.reloadAll(context: context)
            }
        }
    }

    private func shiftMonth(_ delta: Int) {
        monthAnchor = Calendar.current.date(byAdding: .month, value: delta, to: monthAnchor) ?? monthAnchor
    }
}

private struct FeedDetailSheet: View {
    let feed: Feed
    let onDelete: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var confirmDelete = false

    var body: some View {
        ZStack {
            PixelBackground(dark: true)
            VStack(spacing: 16) {
                HStack {
                    Spacer()
                    PixelIconButton(icon: "pixel_close", accessibilityText: "Close", fill: Px.card, action: { dismiss() })
                }
                .padding(.horizontal, 24)
                if let img = PhotoStore.load(filename: feed.photoFilename) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .padding(8)
                        .pixelBox(fill: Px.card, size: .small)
                }
                Text(feed.takenAt.formatted(date: .complete, time: .shortened))
                    .font(PxFont.body)
                    .foregroundStyle(Px.card)
                Button("Delete photo") { confirmDelete = true }
                    .font(PxFont.make(17, .bold))
                    .foregroundStyle(Px.pinkText)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .buttonStyle(PixelButtonStyle(fill: Px.pinkSoft, size: .small))
                Spacer()
            }
            .padding(.top, 16)
        }
        .alert("Delete this feed?", isPresented: $confirmDelete) {
            Button("Delete", role: .destructive) {
                onDelete()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

extension Feed: Identifiable {}

#Preview {
    HistoryView()
        .modelContainer(try! SharedStore.modelContainer())
}
