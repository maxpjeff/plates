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
        ZStack {
            PaperBackground()
            ScrollView {
                VStack(spacing: 20) {
                    if let capy = capys.first, let settings = settingsList.first {
                        let snap = SharedStore.snapshot(capy: capy, settings: settings, feeds: feeds)
                        statsRow(snap: snap, capy: capy)
                        monthCard(capy: capy, settings: settings)
                    }
                    recentGrid
                }
                .padding(24)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.light, for: .navigationBar)
        .capyPaperText()
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("History").font(CapyFont.fredoka(22))
                    .foregroundStyle(Theme.Color.ink)
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

    private func statsRow(snap: CapySnapshot, capy: Capybara) -> some View {
        HStack(spacing: 10) {
            miniStat("Streak", value: "\(snap.streak)", fill: Theme.Color.yellowSoft)
            miniStat("Best", value: "\(capy.bestStreak)", fill: Theme.Color.greenSoft)
            miniStat("Feeds", value: "\(capy.totalFeeds)", fill: Theme.Color.blueSoft)
        }
    }

    private func miniStat(_ title: String, value: String, fill: Color) -> some View {
        VStack(spacing: 4) {
            Text(title).font(CapyFont.nunito(13, .heavy))
            Text(value).font(CapyFont.fredoka(22))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 20).fill(fill))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Theme.Color.ink, lineWidth: 2))
    }

    private func monthCard(capy: Capybara, settings: CapySettings) -> some View {
        let cal = Calendar.current
        let rest = SharedStore.effectiveRestWeekdays(settings: settings, at: monthAnchor)
        let feedsInMonth = feeds.filter {
            cal.isDate($0.takenAt, equalTo: monthAnchor, toGranularity: .month)
        }
        let monthName: String = {
            let f = DateFormatter()
            f.dateFormat = "MMMM yyyy"
            return f.string(from: monthAnchor)
        }()

        return CapyCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Button { shiftMonth(-1) } label: { navArrow("chevron.left") }
                    Spacer()
                    VStack {
                        Text(monthName).font(CapyFont.fredoka(20))
                        Text("\(feedsInMonth.count) feeds").font(CapyFont.nunito(13, .heavy))
                            .foregroundStyle(Theme.Color.textSecondary)
                    }
                    Spacer()
                    Button { shiftMonth(1) } label: { navArrow("chevron.right") }
                }
                let days = daysInMonth(monthAnchor)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                    ForEach(days, id: \.self) { day in
                        let style = DayHistoryHelper.style(
                            for: day,
                            feeds: feeds,
                            restWeekdays: rest,
                            capy: capy,
                            at: Date()
                        )
                        DayToken(
                            label: "\(cal.component(.day, from: day))",
                            style: mapStyle(style)
                        )
                    }
                }
                HStack(spacing: 16) {
                    legendItem("Fed", color: Theme.Color.orangeSoft)
                    legendItem("Rest day", dashed: true)
                }
                .font(CapyFont.nunito(12, .heavy))
            }
            .padding(16)
        }
    }

    private var recentGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent feeds").font(CapyFont.fredoka(22))
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                ForEach(Array(feeds.enumerated()), id: \.element.id) { idx, feed in
                    Button { selectedFeed = feed } label: {
                        if let img = PhotoStore.load(filename: feed.photoFilename) {
                            PolaroidFrame(rotation: idx.isMultiple(of: 2) ? -3 : 2) {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 90, height: 90)
                                    .clipped()
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func navArrow(_ icon: String) -> some View {
        Image(systemName: icon)
            .font(.system(size: 16, weight: .semibold))
            .frame(width: 36, height: 36)
            .background(Circle().fill(Theme.Color.card))
            .overlay(Circle().strokeBorder(Theme.Color.ink, lineWidth: 2))
    }

    private func shiftMonth(_ delta: Int) {
        monthAnchor = Calendar.current.date(byAdding: .month, value: delta, to: monthAnchor) ?? monthAnchor
    }

    private func daysInMonth(_ date: Date) -> [Date] {
        let cal = Calendar.current
        guard let range = cal.range(of: .day, in: .month, for: date),
              let start = cal.date(from: cal.dateComponents([.year, .month], from: date))
        else { return [] }
        return range.compactMap { cal.date(byAdding: .day, value: $0 - 1, to: start) }
    }

    private func legendItem(_ text: String, color: Color = .clear, dashed: Bool = false) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(dashed ? Theme.Color.paper : color)
                .frame(width: 14, height: 14)
                .overlay(
                    Circle().strokeBorder(dashed ? Theme.Color.restOutline : Theme.Color.ink, style: StrokeStyle(lineWidth: 2, dash: dashed ? [3, 2] : []))
                )
            Text(text)
        }
    }

    private func mapStyle(_ s: DayTokenStyle) -> DayToken.Style {
        switch s {
        case .fed: .fed
        case .rest: .rest
        case .missed: .missed
        case .today: .today
        case .asleep: .asleep
        case .scheduledRest: .scheduledRest
        }
    }
}

private struct FeedDetailSheet: View {
    let feed: Feed
    let onDelete: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var confirmDelete = false

    var body: some View {
        ZStack {
            PaperBackground()
            VStack(spacing: 16) {
                if let img = PhotoStore.load(filename: feed.photoFilename) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                Text(feed.takenAt.formatted(date: .complete, time: .shortened))
                    .font(CapyFont.nunito(16))
                Button(role: .destructive) { confirmDelete = true } label: {
                    Text("Delete photo")
                        .font(CapyFont.nunito(14, .heavy))
                }
                Button("Close") { dismiss() }
            }
            .padding()
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
    NavigationStack {
        HistoryView()
    }
    .modelContainer(try! SharedStore.modelContainer())
}
