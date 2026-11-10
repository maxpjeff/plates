import SwiftUI
import WidgetKit

struct CapyEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot?
    let state: AvatarState
    let todayFraction: CGFloat
    let todayLabel: String
    let streak: Int

    var name: String { snapshot?.name ?? "Biscuit" }
}

struct CapyWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> CapyEntry {
        biscuitPlaceholder()
    }

    func getSnapshot(in context: Context, completion: @escaping (CapyEntry) -> Void) {
        completion(currentEntry(at: .now) ?? biscuitPlaceholder())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CapyEntry>) -> Void) {
        guard let base = WidgetSnapshotStore.load() else {
            let place = CapyEntry(date: .now, snapshot: nil, state: .streakLost, todayFraction: 0, todayLabel: "Streak lost", streak: 0)
            completion(Timeline(entries: [place], policy: .atEnd))
            return
        }
        let built = WidgetTimelineBuilder.entries(for: base, from: .now)
        let entries = built.map { entry(at: $0.date, snapshot: $0.snapshot) }
        completion(Timeline(entries: entries.isEmpty ? [placeholder(in: context)] : entries, policy: .atEnd))
    }

    private func currentEntry(at: Date) -> CapyEntry? {
        guard let snap = WidgetSnapshotStore.load() else { return nil }
        return entry(at: at, snapshot: snap)
    }

    private func entry(at: Date, snapshot: WidgetSnapshot) -> CapyEntry {
        let input = snapshot.engineInput(at: at)
        let state = CapyEngine.avatarState(input: input)
        let streak = CapyEngine.streak(input: input)
        return CapyEntry(
            date: at,
            snapshot: snapshot,
            state: state,
            todayFraction: CapyEngine.todayBarFraction(input: input),
            todayLabel: CapyEngine.todayBarLabel(input: input),
            streak: streak
        )
    }

    private func biscuitPlaceholder() -> CapyEntry {
        let snap = WidgetSnapshot(
            name: "Biscuit",
            lastFeedDate: Date(),
            feedDates: [Date()],
            restWeekdays: [],
            streakStart: Date(),
            createdAt: Date(),
            last7Days: Array(repeating: .missed, count: 7)
        )
        return CapyEntry(
            date: .now,
            snapshot: snap,
            state: .lockedIn,
            todayFraction: 1,
            todayLabel: "Done for today",
            streak: 12
        )
    }
}

struct CapyWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    var entry: CapyEntry

    var body: some View {
        Group {
            if entry.snapshot == nil {
                CapyWidgetPlaceholderView()
            } else {
                content
            }
        }
        .widgetURL(AppConstants.feedURL)
        .containerBackground(for: .widget) {
            switch family {
            case .systemSmall:
                if entry.snapshot != nil {
                    WidgetDotPattern(base: entry.state.sceneColor, dot: entry.state.sceneDotColor)
                } else {
                    Theme.Color.card
                }
            case .systemMedium, .systemLarge:
                if entry.snapshot != nil {
                    WidgetDotPattern(base: entry.state.sceneColor, dot: entry.state.sceneDotColor)
                } else {
                    Theme.Color.card
                }
            default:
                Color.clear
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch family {
        case .systemSmall:
            CapySmallWidgetView(entry: entry)
        case .systemMedium:
            CapyMediumWidgetView(entry: entry)
        case .systemLarge:
            CapyLargeWidgetView(entry: entry)
        case .accessoryCircular:
            CapyLockCircularView(entry: entry)
        case .accessoryRectangular:
            CapyLockRectangularView(entry: entry)
        case .accessoryInline:
            CapyLockInlineView(entry: entry)
        default:
            CapySmallWidgetView(entry: entry)
        }
    }
}

@main
struct CapyWidgetBundle: WidgetBundle {
    init() {
        CapyFontLoader.loadIfNeeded()
    }

    var body: some Widget {
        CapyWidget()
    }
}

struct CapyWidget: Widget {
    let kind = "CapyWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CapyWidgetProvider()) { entry in
            CapyWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(AppConstants.appName)
        .description("See how your capybara is doing.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline,
        ])
    }

}

// MARK: - Previews

private func previewSnapshot() -> WidgetSnapshot {
    WidgetSnapshot(
        name: "Biscuit",
        lastFeedDate: Date().addingTimeInterval(-8 * 3600),
        feedDates: [Date()],
        restWeekdays: [1],
        streakStart: Calendar.current.date(byAdding: .day, value: -11, to: .now),
        createdAt: Date(),
        last7Days: [.rest, .fed, .fed, .fed, .fed, .fed, .today]
    )
}

private func previewEntries() -> [CapyEntry] {
    let snap = previewSnapshot()
    return AvatarState.allCases.map { state in
        CapyEntry(
            date: .now,
            snapshot: snap,
            state: state,
            todayFraction: state == .couchMode ? 0.6 : (state == .streakLost ? 0 : 1),
            todayLabel: CapyEngine.todayBarLabel(
                input: snap.engineInput(at: .now)
            ),
            streak: state == .streakLost ? 0 : 12
        )
    }
}

#Preview(as: .systemSmall) {
    CapyWidget()
} timeline: {
    previewEntries()[0]
    previewEntries()[1]
    previewEntries()[2]
    previewEntries()[3]
}

#Preview(as: .systemMedium) {
    CapyWidget()
} timeline: {
    previewEntries()[0]
    previewEntries()[1]
    previewEntries()[2]
    previewEntries()[3]
}

#Preview(as: .systemLarge) {
    CapyWidget()
} timeline: {
    previewEntries()[0]
    previewEntries()[1]
    previewEntries()[2]
    previewEntries()[3]
}

#Preview(as: .accessoryCircular) {
    CapyWidget()
} timeline: {
    previewEntries()[0]
    previewEntries()[1]
    previewEntries()[2]
    previewEntries()[3]
}

#Preview(as: .accessoryRectangular) {
    CapyWidget()
} timeline: {
    previewEntries()[0]
    previewEntries()[1]
    previewEntries()[2]
    previewEntries()[3]
}

#Preview(as: .accessoryInline) {
    CapyWidget()
} timeline: {
    previewEntries()[0]
    previewEntries()[1]
    previewEntries()[2]
    previewEntries()[3]
}
