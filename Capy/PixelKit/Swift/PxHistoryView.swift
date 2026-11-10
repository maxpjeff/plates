// PxHistoryView.swift
// Pixel History screen. Pure UI.

import SwiftUI

struct PxRecentFeed: Identifiable {
    let id = UUID()
    var photo: Image?
    var label: String      // "Today", "Sat", "Fri"
}

struct PxHistoryModel {
    var streak: Int
    var best: Int
    var totalFeeds: Int
    var monthTitle: String        // "November"
    var monthFeeds: Int
    var leadingBlanks: Int        // empty cells before day 1 (0 = month starts on Sunday)
    var days: [PxDayKind]         // one per day of the month, day 1 first
    var recent: [PxRecentFeed]    // newest first
}

struct PxHistoryView: View {
    let model: PxHistoryModel
    var onBack: () -> Void
    var onPreviousMonth: () -> Void
    var onNextMonth: () -> Void
    var onSelectFeed: (Int) -> Void

    private let weekdayLetters = ["S", "M", "T", "W", "T", "F", "S"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    var body: some View {
        ZStack {
            PixelBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    stats
                    calendarCard
                    recentSection
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            PixelIconButton(icon: "pixel_back", accessibilityText: "Back", action: onBack)
            Text("History")
                .font(PxFont.screenTitle)
                .foregroundStyle(Px.ink)
        }
    }

    private var stats: some View {
        HStack(spacing: 14) {
            StatCard(label: "Streak", value: "\(model.streak)", fill: Px.yellow, labelColor: Px.yellowText, valueSize: 28)
            StatCard(label: "Best", value: "\(model.best)", fill: Px.greenSoft, labelColor: Px.greenText, valueSize: 28)
            StatCard(label: "Feeds", value: "\(model.totalFeeds)", fill: Px.blueSoft, labelColor: Px.blueText, valueSize: 28)
        }
    }

    private var calendarCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Text(model.monthTitle.uppercased())
                    .font(PxFont.section)
                    .foregroundStyle(Px.ink)
                Spacer()
                Text("\(model.monthFeeds) feeds")
                    .font(PxFont.make(15, .medium))
                    .foregroundStyle(Px.textSecondary)
                Button(action: onPreviousMonth) {
                    PixelIcon("pixel_back", size: 16)
                }
                .accessibilityLabel("Previous month")
                Button(action: onNextMonth) {
                    PixelIcon("pixel_back", size: 16).scaleEffect(x: -1, y: 1)
                }
                .accessibilityLabel("Next month")
            }

            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(0..<7, id: \.self) { i in
                    Text(weekdayLetters[i])
                        .font(PxFont.micro)
                        .foregroundStyle(Px.textSecondary)
                }
            }

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(0..<(model.leadingBlanks + model.days.count), id: \.self) { index in
                    if index < model.leadingBlanks {
                        Color.clear.frame(height: 34)
                    } else {
                        let day = index - model.leadingBlanks
                        DayToken(kind: model.days[day], side: 34, number: day + 1)
                    }
                }
            }

            HStack(spacing: 16) {
                legend(.posted, "Posted")
                legend(.rest, "Rest day")
                legend(.missed, "Missed")
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 14)
        .pixelBox(fill: Px.card, size: .large)
    }

    private func legend(_ kind: PxDayKind, _ text: String) -> some View {
        HStack(spacing: 6) {
            DayToken(kind: kind, side: 14, number: nil, border: 2)
                .overlay { if kind == .posted { Px.orangeSoft.padding(2) } }  // hide the check at this size
            Text(text)
                .font(PxFont.make(14, .medium))
                .foregroundStyle(Px.textSecondary)
        }
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("RECENT FEEDS")
                .font(PxFont.section)
                .foregroundStyle(Px.ink)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 3), spacing: 18) {
                ForEach(Array(model.recent.enumerated()), id: \.element.id) { index, feed in
                    Button { onSelectFeed(index) } label: {
                        VStack(spacing: 4) {
                            ZStack {
                                Px.photoPlaceholder
                                if let photo = feed.photo {
                                    photo.resizable().scaledToFill()
                                }
                            }
                            .aspectRatio(1, contentMode: .fit)
                            .clipped()
                            Text(feed.label.uppercased())
                                .font(PxFont.make(13, .semibold))
                                .foregroundStyle(Px.ink)
                        }
                        .padding(5)
                        .pixelBox(fill: Px.card, size: .small)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

#Preview("History") {
    let fed: Set<Int> = [1, 3, 4, 6, 7]
    let rest: Set<Int> = [2, 5, 8]
    let days: [PxDayKind] = (1...30).map { n in
        if n == 9 { return .todayPosted }
        if fed.contains(n) { return .posted }
        if rest.contains(n) { return .rest }
        return .future
    }
    return PxHistoryView(
        model: PxHistoryModel(
            streak: 12, best: 21, totalFeeds: 47,
            monthTitle: "November", monthFeeds: 6,
            leadingBlanks: 0, days: days,
            recent: [PxRecentFeed(photo: nil, label: "Today"),
                     PxRecentFeed(photo: nil, label: "Sat"),
                     PxRecentFeed(photo: nil, label: "Fri")]
        ),
        onBack: {}, onPreviousMonth: {}, onNextMonth: {}, onSelectFeed: { _ in }
    )
}
