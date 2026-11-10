import SwiftUI
import WidgetKit

struct CapyWidgetPlaceholderView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "pawprint.fill")
                .font(.system(size: 28, weight: .bold))
            Text("Open the app to meet your capybara")
                .font(CapyFont.nunito(13, .heavy))
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(Theme.Color.ink)
        .padding()
    }
}

struct CapySmallWidgetView: View {
    let entry: CapyEntry

    var body: some View {
        let state = entry.state
        VStack(spacing: 6) {
            HStack {
                Text(entry.name)
                    .font(CapyFont.fredoka(16))
                    .foregroundStyle(Theme.Color.ink)
                    .lineLimit(1)
                Spacer(minLength: 4)
                if entry.streak > 0 {
                    WidgetStreakPill(streak: entry.streak)
                }
            }
            WidgetCapybara(state: state, maxHeight: 86, maxWidth: state == .couchMode ? 128 : nil)
                .frame(height: 86)
            if state == .streakLost {
                Text("Tap to wake \(entry.name) up")
                    .font(CapyFont.nunito(12, .heavy))
                    .foregroundStyle(Theme.Color.textSecondary)
                    .multilineTextAlignment(.center)
            } else {
                HStack(spacing: 8) {
                    WidgetMiniEnergyBar(
                        fraction: entry.todayFraction,
                        fillColor: state.todayBarFillColor
                    )
                    Text(entry.todayLabel)
                        .font(CapyFont.nunito(12, .heavy))
                        .foregroundStyle(state.todayBarTextColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .fixedSize()
                }
            }
        }
        .padding(12)
    }
}

struct CapyMediumWidgetView: View {
    let entry: CapyEntry

    var body: some View {
        let state = entry.state
        HStack(spacing: 0) {
            ZStack(alignment: .bottom) {
                WidgetCapybara(state: state, maxHeight: 136, maxWidth: state == .couchMode ? 128 : nil)
                    .padding(.bottom, 4)
            }
            .frame(width: 150)
            .overlay(alignment: .trailing) {
                Rectangle()
                    .fill(Theme.Color.ink)
                    .frame(width: 2.5)
            }

            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(entry.name)
                            .font(CapyFont.fredoka(19))
                            .lineLimit(1)
                        Spacer(minLength: 4)
                        if entry.streak > 0 {
                            WidgetStreakPill(streak: entry.streak, fontSize: 12)
                        }
                    }
                    Text(state.label)
                        .font(CapyFont.fredoka(12))
                        .foregroundStyle(state.pillTextColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(state.pillColor)
                                .overlay(Capsule().strokeBorder(Theme.Color.ink, lineWidth: 2))
                        )
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Today")
                            .font(CapyFont.nunito(12, .heavy))
                        Spacer()
                        Text(entry.todayLabel)
                            .font(CapyFont.nunito(12, .heavy))
                            .foregroundStyle(state.todayBarTextColor)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    WidgetMiniEnergyBar(
                        fraction: entry.todayFraction,
                        fillColor: state.todayBarFillColor
                    )
                }

                WidgetLast7DaysRow(statuses: entry.snapshot?.last7Days ?? [], circleSize: 18)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
        }
    }
}

struct CapyLargeWidgetView: View {
    let entry: CapyEntry

    var body: some View {
        let state = entry.state
        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                VStack(spacing: 0) {
                    HStack {
                        Text(entry.name)
                            .font(CapyFont.fredoka(20))
                        Spacer()
                        if entry.streak > 0 {
                            WidgetStreakPill(streak: entry.streak, fontSize: 12)
                        }
                    }
                    .foregroundStyle(Theme.Color.ink)
                    .padding(.horizontal, 14)
                    .padding(.top, 10)

                    WidgetCapybara(state: state, maxHeight: 140, maxWidth: state == .couchMode ? 178 : nil)
                        .frame(height: 120)
                        .padding(.horizontal, 8)
                }
            }
            .frame(height: 164)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Theme.Color.ink)
                    .frame(height: 2.5)
            }

            VStack(alignment: .leading, spacing: 9) {
                HStack {
                    Text(state.label)
                        .font(CapyFont.fredoka(12))
                        .foregroundStyle(state.pillTextColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(state.pillColor)
                                .overlay(Capsule().strokeBorder(Theme.Color.ink, lineWidth: 2))
                        )
                    Spacer()
                    if let last = entry.snapshot?.lastFeedDate {
                        Text(lastFedCaption(last, at: entry.date))
                            .font(CapyFont.nunito(13, .bold))
                            .foregroundStyle(Theme.Color.textSecondary)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Today")
                            .font(CapyFont.nunito(12, .heavy))
                        Spacer()
                        Text(entry.todayLabel)
                            .font(CapyFont.nunito(12, .heavy))
                            .foregroundStyle(state.todayBarTextColor)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    WidgetMiniEnergyBar(
                        fraction: entry.todayFraction,
                        fillColor: state.todayBarFillColor,
                        height: 12
                    )
                }

                WidgetLast7DaysLargeRow(statuses: entry.snapshot?.last7Days ?? [])

                Spacer(minLength: 0)

                Link(destination: AppConstants.feedURL) {
                    HStack(spacing: 6) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 14, weight: .bold))
                        Text(state.feedButtonTitle(name: entry.name))
                            .font(CapyFont.fredoka(14))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .foregroundStyle(Theme.Color.ink)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background {
                        ZStack {
                            Capsule().fill(Theme.Color.ink).offset(y: 4)
                            Capsule()
                                .fill(Theme.Color.orange)
                                .overlay(Capsule().strokeBorder(Theme.Color.ink, lineWidth: 2.5))
                        }
                    }
                }
            }
            .padding(.top, 10)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }
}

private struct WidgetLast7DaysLargeRow: View {
    let statuses: [DayStatus]
    private let letters = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        HStack {
            ForEach(Array(statuses.enumerated()), id: \.offset) { idx, status in
                VStack(spacing: 4) {
                    Text(letters[idx % 7])
                        .font(CapyFont.nunito(10, .heavy))
                        .foregroundStyle(Theme.Color.textSecondary)
                    WidgetDayCircle(status: status, size: 22)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

private func lastFedCaption(_ last: Date, at: Date) -> String {
    let seconds = at.timeIntervalSince(last)
    let hrs = max(1, Int(seconds / 3600))
    if hrs < 24 { return "Last fed \(hrs) hrs ago" }
    return "Last fed \(hrs / 24)d ago"
}

struct CapyLockCircularView: View {
    @Environment(\.widgetRenderingMode) private var renderingMode
    let entry: CapyEntry

    var body: some View {
        let tint = renderingMode != .fullColor
        GeometryReader { geo in
            ZStack {
                AccessoryWidgetBackground()
                WidgetCapybara(
                    state: entry.state,
                    useTint: tint,
                    maxHeight: geo.size.height * 0.62,
                    maxWidth: geo.size.width * 0.85
                )
                .widgetAccentable(tint)
            }
        }
    }
}

struct CapyLockRectangularView: View {
    @Environment(\.widgetRenderingMode) private var renderingMode
    let entry: CapyEntry

    var body: some View {
        let tint = renderingMode != .fullColor
        HStack(spacing: 8) {
            WidgetCapybara(state: entry.state, useTint: tint, maxHeight: 56, maxWidth: 64)
                .frame(width: 56, height: 56, alignment: .bottom)
                .widgetAccentable(tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.state.label)
                    .font(CapyFont.fredoka(17))
                    .lineLimit(1)
                Text("\(entry.todayLabel) · \(entry.streak) days")
                    .font(CapyFont.nunito(13, .bold))
                    .lineLimit(1)
            }
        }
    }
}

struct CapyLockInlineView: View {
    let entry: CapyEntry

    var body: some View {
        Text("\(entry.name) · \(entry.state.label) · \(entry.todayLabel)")
            .font(CapyFont.nunito(12, .heavy))
    }
}
