// PxFedView.swift
// Pixel "Fed" confirmation screen. Pure UI.

import SwiftUI

struct PxFedModel {
    var name: String
    var photo: Image?
    var timeText: String      // "MON 6:42 PM"
    var dayNumber: Int        // streak day shown on the polaroid
    var subtitle: String      // "Locked in for today. See you tomorrow." etc.
    var streak: Int
}

struct PxFedView: View {
    let model: PxFedModel
    var onDone: () -> Void

    var body: some View {
        ZStack {
            PixelBackground()
            Confetti()
                .allowsHitTesting(false)

            VStack(spacing: 18) {
                hero
                VStack(spacing: 6) {
                    Text("\(model.name) is fed!")
                        .font(PxFont.screenTitle)
                        .foregroundStyle(Px.ink)
                        .multilineTextAlignment(.center)
                    Text(model.subtitle)
                        .font(PxFont.body)
                        .foregroundStyle(Px.textSecondary)
                        .multilineTextAlignment(.center)
                }
                HStack(spacing: 18) {
                    StatCard(label: "Streak", value: "\(model.streak) days", fill: Px.yellow, labelColor: Px.yellowText)
                    StatCard(label: "Today", value: "Locked in", fill: Px.greenSoft, labelColor: Px.greenText, valueSize: 26)
                }
                Spacer(minLength: 0)
                PixelPrimaryButton(title: "Done", icon: nil, action: onDone)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 16)
        }
        .onAppear {
            #if canImport(UIKit)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            #endif
        }
    }

    private var hero: some View {
        ZStack(alignment: .bottomTrailing) {
            PolaroidView(
                photo: model.photo,
                leftText: model.timeText,
                rightText: "Day \(model.dayNumber)",
                width: 148,
                photoHeight: 140
            )
            .rotationEffect(.degrees(-4))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.top, 8)

            CapySprite(status: .lockedIn, maxHeight: 200, maxWidth: 200)
                .steppedPop(trigger: "fed")
        }
        .frame(height: 290)
    }
}

/// 8pt solid squares scattered over the top half. Positions are fractions of the screen size.
private struct Confetti: View {
    private let pieces: [(x: CGFloat, y: CGFloat, color: Color, size: CGFloat)] = [
        (0.10, 0.08, Px.flame, 8),
        (0.86, 0.12, Color(hex: 0x7BC043), 8),
        (0.07, 0.28, Color(hex: 0x8FD3F4), 8),
        (0.90, 0.34, Px.flame, 8),
        (0.66, 0.17, Color(hex: 0xF7B733), 8),
        (0.14, 0.42, Color(hex: 0xE2533A), 8),
        (0.78, 0.07, Px.yellow, 16)
    ]

    var body: some View {
        GeometryReader { geo in
            ForEach(pieces.indices, id: \.self) { i in
                let p = pieces[i]
                Rectangle()
                    .fill(p.color)
                    .frame(width: p.size, height: p.size)
                    .position(x: geo.size.width * p.x, y: geo.size.height * p.y)
            }
        }
        .ignoresSafeArea()
    }
}

#Preview("Fed") {
    PxFedView(
        model: PxFedModel(
            name: "Biscuit",
            photo: nil,
            timeText: "Mon 6:42 PM",
            dayNumber: 13,
            subtitle: "Locked in for today. See you tomorrow.",
            streak: 13
        ),
        onDone: {}
    )
}
