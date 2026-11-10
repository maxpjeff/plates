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
            last7Days: Array(repeating: .fed, count: 7)
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
                PixelBackground()
                VStack(spacing: 8) {
                    PixelIcon("pixel_camera", size: 28)
                    Text("Open the app to meet your capybara")
                        .font(PxFont.caption)
                        .multilineTextAlignment(.center)
                }
                .foregroundStyle(Px.ink)
                .padding()
            } else {
                PxWidgetEntryView(model: WidgetPxModel.build(from: entry))
            }
        }
        .widgetURL(AppConstants.feedURL)
    }
}

@main
struct CapyWidgetBundle: WidgetBundle {
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
        .contentMarginsDisabled()
    }
}
