// PxHomeView.swift
// Pixel Home screen. Pure UI: it only reads PxHomeModel and calls the closures.
// Build PxHomeModel from your existing view model (see CURSOR_PROMPT.md, Step 4).

import SwiftUI

struct PxDay: Identifiable {
    let id = UUID()
    let letter: String      // "M", "T", ...
    let kind: PxDayKind
}

struct PxHomeModel {
    var name: String
    var dateLine: String           // "MONDAY, NOV 9"
    var status: PxStatus
    var streak: Int
    var caption: String            // "Posted at 6:42 PM", "Haven't posted today", ...
    var todayFraction: Double      // 0...1, fills the Today bar
    var todayText: String          // "Done for today", "8 hrs left today", "Rest day", "Streak lost"
    var last7: [PxDay]             // oldest -> today (7 items)

    var buttonTitle: String {
        switch status {
        case .couchMode: return "Get \(name) off the couch"
        case .streakLost: return "Wake \(name) up"
        default: return "Feed \(name)"
        }
    }
}

struct PxHomeView: View {
    let model: PxHomeModel
    var onFeed: () -> Void
    var onHistory: () -> Void
    var onSettings: () -> Void

    var body: some View {
        ZStack {
            PixelBackground()

            VStack(alignment: .leading, spacing: 20) {
                header
                heroCard
                todaySection
                weekSection
                Spacer(minLength: 0)
                PixelPrimaryButton(title: model.buttonTitle, icon: "pixel_camera", action: onFeed)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .bottom, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(model.dateLine.uppercased())
                    .font(PxFont.dateLine)
                    .tracking(1)
                    .foregroundStyle(Px.textSecondary)
                Text(model.name)
                    .font(PxFont.displayName)
                    .foregroundStyle(Px.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            Spacer(minLength: 0)
            HStack(spacing: 12) {
                StreakPill(streak: model.streak)
                PixelIconButton(icon: "pixel_calendar", accessibilityText: "History", action: onHistory)
                PixelIconButton(icon: "pixel_gear", accessibilityText: "Settings", action: onSettings)
            }
        }
    }

    // MARK: Hero

    private var heroCard: some View {
        VStack(spacing: 0) {
            PixelScene(status: model.status, height: 240) {
                CapySprite(status: model.status, maxHeight: 216, maxWidth: 290)
                    .id(model.status)
                    .steppedPop(trigger: model.status)
            }
            Rectangle().fill(Px.ink).frame(height: 4)
            HStack(spacing: 10) {
                StatusPill(status: model.status)
                Spacer(minLength: 0)
                Text(model.caption)
                    .font(PxFont.make(15, .medium))
                    .foregroundStyle(Px.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .pixelBox(fill: Px.card, size: .large)
    }

    // MARK: Today

    private var todaySection: some View {
        VStack(spacing: 10) {
            HStack {
                Text("TODAY")
                    .font(PxFont.label)
                    .foregroundStyle(Px.ink)
                Spacer()
                Text(model.todayText.uppercased())
                    .font(PxFont.label)
                    .foregroundStyle(model.status.accentText)
            }
            SegmentedBar(fraction: model.todayFraction, color: model.status.barColor)
        }
    }

    // MARK: Last 7 days

    private var weekSection: some View {
        VStack(spacing: 10) {
            HStack(spacing: 0) {
                ForEach(Array(model.last7.enumerated()), id: \.element.id) { index, day in
                    VStack(spacing: 6) {
                        Text(day.letter)
                            .font(PxFont.micro)
                            .foregroundStyle(index == model.last7.count - 1 ? Px.ink : Px.textSecondary)
                        DayToken(kind: day.kind, side: 30)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            Text("Dashed = rest day. Rest days don't break your streak.")
                .font(PxFont.caption)
                .foregroundStyle(Px.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Preview data

extension PxHomeModel {
    static func sample(_ status: PxStatus) -> PxHomeModel {
        let kinds: [PxDayKind] = [.posted, .posted, .rest, .posted, .posted, .rest,
                                  status == .lockedIn ? .todayPosted : .today]
        let letters = ["T", "W", "T", "F", "S", "S", "M"]
        return PxHomeModel(
            name: "Biscuit",
            dateLine: "Monday, Nov 9",
            status: status,
            streak: status == .streakLost ? 0 : 12,
            caption: {
                switch status {
                case .lockedIn: return "Posted at 6:42 PM"
                case .recovering: return "Rest day. Enjoy it."
                case .couchMode: return "Haven't posted today"
                case .streakLost: return "One photo starts a new streak"
                }
            }(),
            todayFraction: {
                switch status {
                case .lockedIn, .recovering: return 1
                case .couchMode: return 0.35
                case .streakLost: return 0
                }
            }(),
            todayText: {
                switch status {
                case .lockedIn: return "Done for today"
                case .recovering: return "Rest day"
                case .couchMode: return "8 hrs left today"
                case .streakLost: return "Streak lost"
                }
            }(),
            last7: zip(letters, kinds).map { PxDay(letter: $0, kind: $1) }
        )
    }
}

#Preview("Home – Locked in") {
    PxHomeView(model: .sample(.lockedIn), onFeed: {}, onHistory: {}, onSettings: {})
}

#Preview("Home – Couch mode") {
    PxHomeView(model: .sample(.couchMode), onFeed: {}, onHistory: {}, onSettings: {})
}

#Preview("Home – Chud") {
    PxHomeView(model: .sample(.streakLost), onFeed: {}, onHistory: {}, onSettings: {})
}
