import SwiftUI

struct WidgetDotPattern: View {
    let base: Color
    let dot: Color

    var body: some View {
        Canvas { context, size in
            let spacing: CGFloat = 14
            let radius: CGFloat = 1.3
            var y = spacing / 2
            while y < size.height {
                var x = spacing / 2
                while x < size.width {
                    let rect = CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
                    context.fill(Path(ellipseIn: rect), with: .color(dot))
                    x += spacing
                }
                y += spacing
            }
        }
        .background(base)
    }
}

struct WidgetCapybara: View {
    let state: AvatarState
    var useTint = false
    let maxHeight: CGFloat
    var maxWidth: CGFloat?

    var body: some View {
        let width = maxWidth ?? (state == .couchMode ? 178 : 220)
        AvatarView(state: state, useTintAsset: useTint, allowsMotion: false)
            .frame(maxWidth: width, maxHeight: maxHeight)
            .frame(maxWidth: .infinity, maxHeight: maxHeight, alignment: .bottom)
    }
}

struct WidgetMiniEnergyBar: View {
    var fraction: CGFloat
    var fillColor: Color
    var height: CGFloat = 10

    var body: some View {
        GeometryReader { geo in
            let w = max(0, min(geo.size.width, geo.size.width * fraction))
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Theme.Color.card)
                    .overlay(Capsule().strokeBorder(Theme.Color.ink, lineWidth: 2))
                if fraction > 0 {
                    Capsule()
                        .fill(fillColor)
                        .frame(width: w)
                }
            }
        }
        .frame(height: height)
    }
}

struct WidgetStreakPill: View {
    let streak: Int
    var fontSize: CGFloat = 12

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .font(.system(size: fontSize - 1, weight: .bold))
                .foregroundStyle(Theme.Color.flame)
            Text("\(streak)")
                .font(CapyFont.fredoka(fontSize))
        }
        .foregroundStyle(Theme.Color.ink)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color(capyHex: "FFD08A"))
                .overlay(Capsule().strokeBorder(Theme.Color.ink, lineWidth: 2))
        )
    }
}

struct WidgetDayCircle: View {
    let status: DayStatus
    var size: CGFloat = 18
    var letter: String?

    var body: some View {
        ZStack {
            switch status {
            case .fed:
                Circle()
                    .fill(Color(capyHex: "FFB84D"))
                    .overlay(Circle().strokeBorder(Theme.Color.ink, lineWidth: 2))
            case .rest:
                Circle()
                    .fill(Theme.Color.card)
                    .overlay(
                        Circle()
                            .strokeBorder(Theme.Color.restOutline, style: StrokeStyle(lineWidth: 2, dash: [4, 3]))
                    )
            case .today:
                Circle()
                    .fill(Color(capyHex: "FF9F43"))
                    .overlay(Circle().strokeBorder(Theme.Color.ink, lineWidth: 2))
            case .missed:
                Circle()
                    .strokeBorder(Theme.Color.restOutline.opacity(0.35), lineWidth: 2)
            }
            if let letter {
                Text(letter)
                    .font(CapyFont.nunito(size > 20 ? 11 : 10, .heavy))
                    .foregroundStyle(status == .today ? Theme.Color.ink : Theme.Color.textSecondary)
            }
        }
        .frame(width: size, height: size)
    }
}

private func weekdayLetter(index: Int) -> String {
    ["S", "M", "T", "W", "T", "F", "S"][index]
}

struct WidgetLast7DaysRow: View {
    let statuses: [DayStatus]
    var circleSize: CGFloat = 18
    var showLetters: Bool = false

    var body: some View {
        HStack {
            ForEach(Array(statuses.enumerated()), id: \.offset) { idx, status in
                VStack(spacing: showLetters ? 4 : 0) {
                    if showLetters {
                        Text(weekdayLetter(index: idx))
                            .font(CapyFont.nunito(10, .heavy))
                            .foregroundStyle(Theme.Color.textSecondary)
                    }
                    WidgetDayCircle(status: status, size: circleSize, letter: showLetters ? nil : nil)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}
