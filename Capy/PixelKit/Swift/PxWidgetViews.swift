// PxWidgetViews.swift
// Pixel widget views. Add to the WIDGET target only (it imports WidgetKit).
// PxTheme.swift and PxComponents.swift must also be in the widget target.
//
// IMPORTANT: add .contentMarginsDisabled() to your WidgetConfiguration so the
// medium and large scenes reach the edges (the views add their own padding).

import SwiftUI
import WidgetKit

struct PxWidgetModel {
    var name: String
    var status: PxStatus
    var streak: Int
    var todayFraction: Double   // 0...1
    var shortText: String       // "DONE", "REST", "8H", "LOST"
    var caption: String         // "Posted at 6:42 PM", "Haven't posted today", ...
    var last7: [PxDayKind]      // oldest -> today
    var last7Letters: [String]  // ["W","T","F","S","S","M","T"]

    var buttonTitle: String {
        switch status {
        case .couchMode: return "Get \(name) off the couch"
        case .streakLost: return "Wake \(name) up"
        default: return "Feed \(name)"
        }
    }

    static let feedURL = URL(string: "capy://feed")!
}

// MARK: - Picks the right view for the family

struct PxWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let model: PxWidgetModel

    var body: some View {
        switch family {
        case .systemSmall: PxSmallWidget(model: model)
        case .systemMedium: PxMediumWidget(model: model)
        case .systemLarge: PxLargeWidget(model: model)
        case .accessoryCircular: PxCircularWidget(model: model)
        case .accessoryRectangular: PxRectangularWidget(model: model)
        case .accessoryInline: PxInlineWidget(model: model)
        default: PxSmallWidget(model: model)
        }
    }
}

// MARK: - Small

struct PxSmallWidget: View {
    let model: PxWidgetModel

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(model.name)
                    .font(PxFont.make(18, .bold))
                    .foregroundStyle(Px.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 4)
                StreakPill(streak: model.streak, compact: true)
            }
            Spacer(minLength: 2)
            CapySprite(status: model.status, maxHeight: 78, maxWidth: 124, bobs: false)
            Spacer(minLength: 2)
            if model.status == .streakLost {
                Text("Tap to wake \(model.name) up")
                    .font(PxFont.make(13, .semibold))
                    .foregroundStyle(Px.pinkText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            } else {
                HStack(spacing: 6) {
                    SegmentedBar(fraction: model.todayFraction, color: model.status.barColor,
                                 segments: 8, segmentHeight: 8, boxSize: .widget)
                    Text(model.shortText)
                        .font(PxFont.make(13, .bold))
                        .foregroundStyle(model.status.accentText)
                }
            }
        }
        .padding(12)
        .containerBackground(for: .widget) {
            PixelGrid(background: model.status.sceneColor, line: model.status.sceneGrid)
        }
        .widgetURL(PxWidgetModel.feedURL)
    }
}

// MARK: - Medium

struct PxMediumWidget: View {
    let model: PxWidgetModel

    var body: some View {
        HStack(spacing: 0) {
            ZStack(alignment: .bottom) {
                PixelGrid(background: model.status.sceneColor, line: model.status.sceneGrid)
                CapySprite(status: model.status, maxHeight: 126, maxWidth: 132, bobs: false)
                    .padding(.bottom, 8)
            }
            .frame(width: 146)
            .clipped()

            Rectangle().fill(Px.ink).frame(width: 4)

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(model.name)
                        .font(PxFont.make(21, .bold))
                        .foregroundStyle(Px.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Spacer(minLength: 4)
                    StreakPill(streak: model.streak, compact: true)
                }
                StatusPill(status: model.status, compact: true)
                    .padding(.top, 4)
                Spacer(minLength: 4)
                HStack {
                    Text("TODAY").font(PxFont.make(13, .bold)).foregroundStyle(Px.ink)
                    Spacer()
                    Text(model.shortText).font(PxFont.make(13, .bold)).foregroundStyle(model.status.accentText)
                }
                SegmentedBar(fraction: model.todayFraction, color: model.status.barColor,
                             segments: 10, segmentHeight: 8, boxSize: .widget)
                    .padding(.top, 4)
                Spacer(minLength: 4)
                HStack(spacing: 5) {
                    ForEach(Array(model.last7.enumerated()), id: \.offset) { _, kind in
                        DayToken(kind: kind, side: 16, border: 2)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .containerBackground(for: .widget) { Px.card }
        .widgetURL(PxWidgetModel.feedURL)
    }
}

// MARK: - Large

struct PxLargeWidget: View {
    let model: PxWidgetModel

    var body: some View {
        VStack(spacing: 0) {
            PixelScene(status: model.status, height: 156, showSparkles: false) {
                CapySprite(status: model.status, maxHeight: 128, maxWidth: 180, bobs: false)
            }
            .overlay(alignment: .topLeading) {
                Text(model.name)
                    .font(PxFont.make(22, .bold))
                    .foregroundStyle(Px.ink)
                    .padding(.leading, 14)
                    .padding(.top, 10)
            }
            .overlay(alignment: .topTrailing) {
                StreakPill(streak: model.streak, compact: true)
                    .padding(.trailing, 14)
                    .padding(.top, 12)
            }

            Rectangle().fill(Px.ink).frame(height: 4)

            VStack(spacing: 10) {
                HStack {
                    StatusPill(status: model.status, compact: true)
                    Spacer()
                    Text(model.caption)
                        .font(PxFont.make(14, .medium))
                        .foregroundStyle(Px.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                VStack(spacing: 4) {
                    HStack {
                        Text("TODAY").font(PxFont.make(14, .bold)).foregroundStyle(Px.ink)
                        Spacer()
                        Text(model.shortText).font(PxFont.make(14, .bold)).foregroundStyle(model.status.accentText)
                    }
                    SegmentedBar(fraction: model.todayFraction, color: model.status.barColor,
                                 segments: 12, segmentHeight: 10, boxSize: .widget)
                }
                HStack(spacing: 0) {
                    ForEach(Array(model.last7.enumerated()), id: \.offset) { index, kind in
                        VStack(spacing: 3) {
                            Text(index < model.last7Letters.count ? model.last7Letters[index] : "")
                                .font(PxFont.make(12, .semibold))
                                .foregroundStyle(Px.textSecondary)
                            DayToken(kind: kind, side: 20, border: 2)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                Spacer(minLength: 0)
                Link(destination: PxWidgetModel.feedURL) {
                    HStack(spacing: 8) {
                        PixelIcon("pixel_camera", size: 18)
                        Text(model.buttonTitle)
                            .font(PxFont.make(17, .bold))
                            .foregroundStyle(Px.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .frame(maxWidth: .infinity, minHeight: 32)
                    .pixelBox(fill: Px.orange, size: .small)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 14)
        }
        .containerBackground(for: .widget) { Px.card }
    }
}

// MARK: - Lock screen

struct PxCircularWidget: View {
    let model: PxWidgetModel

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            Image(model.status.tintSprite)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .padding(7)
                .widgetAccentable()
        }
        .containerBackground(for: .widget) { Color.clear }
        .widgetURL(PxWidgetModel.feedURL)
    }
}

struct PxRectangularWidget: View {
    let model: PxWidgetModel

    var body: some View {
        HStack(spacing: 6) {
            Image(model.status.tintSprite)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)
                .widgetAccentable()
            VStack(alignment: .leading, spacing: 0) {
                Text(model.status.label)
                    .font(PxFont.make(15, .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text("\(model.shortText) · \(model.streak) days")
                    .font(PxFont.make(13, .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            Spacer(minLength: 0)
        }
        .containerBackground(for: .widget) { Color.clear }
        .widgetURL(PxWidgetModel.feedURL)
    }
}

struct PxInlineWidget: View {
    let model: PxWidgetModel

    var body: some View {
        Text("\(model.name) · \(model.status.label.capitalized) · \(model.shortText)")
            .containerBackground(for: .widget) { Color.clear }
    }
}

// MARK: - Preview data

extension PxWidgetModel {
    static func sample(_ status: PxStatus) -> PxWidgetModel {
        PxWidgetModel(
            name: "Biscuit",
            status: status,
            streak: status == .streakLost ? 0 : 12,
            todayFraction: status == .couchMode ? 0.35 : (status == .streakLost ? 0 : 1),
            shortText: {
                switch status {
                case .lockedIn: return "DONE"
                case .recovering: return "REST"
                case .couchMode: return "8H"
                case .streakLost: return "LOST"
                }
            }(),
            caption: status == .couchMode ? "Haven't posted today" : "Posted at 6:42 PM",
            last7: [.posted, .rest, .posted, .posted, .rest, .posted, status == .lockedIn ? .todayPosted : .today],
            last7Letters: ["W", "T", "F", "S", "S", "M", "T"]
        )
    }
}
