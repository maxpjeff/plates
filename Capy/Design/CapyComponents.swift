import SwiftUI

/// Hard offset shadow behind fill; content must be stacked above this in a ZStack.
struct HardShadowFill<S: InsettableShape>: View {
    let shape: S
    let fill: Color
    var shadowX: CGFloat = 0
    var shadowY: CGFloat = Theme.Layout.hardShadow
    var lineWidth: CGFloat = Theme.Layout.border

    var body: some View {
        ZStack {
            shape.fill(Theme.Color.ink)
                .offset(x: shadowX, y: shadowY)
            shape.fill(fill)
                .overlay(shape.strokeBorder(Theme.Color.ink, lineWidth: lineWidth))
        }
    }
}

struct CapyCard<Content: View>: View {
    @ViewBuilder var content: () -> Content

    private let cardShape = RoundedRectangle(cornerRadius: Theme.Layout.cardRadius, style: .continuous)

    var body: some View {
        content()
            .background {
                HardShadowFill(shape: cardShape, fill: Theme.Color.card)
            }
    }
}

struct CapyPrimaryButton: View {
    let title: String
    var icon: String? = nil
    var action: () -> Void

    @State private var pressed = false

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            let lift = pressed ? 4.0 : 0.0
            let shadowY = pressed ? 2.0 : Theme.Layout.hardShadow
            ZStack {
                Capsule()
                    .fill(Theme.Color.ink)
                    .offset(y: shadowY)
                Capsule()
                    .fill(Theme.Color.orange)
                    .overlay(Capsule().strokeBorder(Theme.Color.ink, lineWidth: Theme.Layout.border))
                    .offset(y: lift)
                HStack(spacing: 10) {
                if let icon {
                    CapySymbol(systemName: icon, size: 20)
                }
                    Text(title)
                        .font(CapyFont.fredoka(22))
                }
                .foregroundStyle(Theme.Color.ink)
                .offset(y: lift)
            }
            .frame(maxWidth: .infinity)
            .frame(height: Theme.Layout.primaryButtonHeight)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in pressed = true }
                .onEnded { _ in pressed = false }
        )
        .accessibilityLabel(title)
    }
}

struct CapyPill: View {
    let title: String
    var fill: Color = Theme.Color.yellowSoft
    var icon: String? = nil

    var body: some View {
        HStack(spacing: 6) {
            if let icon {
                CapySymbol(systemName: icon, size: 14, color: Theme.Color.flame)
            }
            Text(title)
                .font(CapyFont.nunito(14, .heavy))
        }
        .foregroundStyle(Theme.Color.ink)
        .padding(.horizontal, 14)
        .frame(height: 44)
        .background {
            HardShadowFill(shape: Capsule(), fill: fill, shadowY: 3)
        }
    }
}

struct StatusPill: View {
    let state: CapyState

    var fill: Color {
        switch state {
        case .lockedIn: Theme.Color.greenSoft
        case .chilling: Theme.Color.yellowSoft
        case .couch: Theme.Color.lilacSoft
        case .restDay: Theme.Color.blueSoft
        case .asleep: Theme.Color.asleepGray.opacity(0.35)
        case .cheering: Theme.Color.greenSoft
        case .peeking: Theme.Color.yellowSoft
        }
    }

    var textColor: Color {
        switch state {
        case .lockedIn: Theme.Color.greenText
        case .restDay: Theme.Color.blueText
        default: Theme.Color.ink
        }
    }

    var body: some View {
        Text(state.statusLabel)
            .font(CapyFont.nunito(14, .heavy))
            .foregroundStyle(textColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(fill)
                    .overlay(Capsule().strokeBorder(Theme.Color.ink, lineWidth: 2))
            )
    }
}

struct EnergyBar: View {
    var fraction: CGFloat
    var state: CapyState
    var paused: Bool

    private var fillColor: Color {
        if paused { return Theme.Color.blueSoft }
        switch state {
        case .lockedIn: return Theme.Color.green
        case .chilling: return Theme.Color.yellowSoft
        case .couch: return Theme.Color.flame
        case .asleep: return Theme.Color.asleepGray
        case .restDay: return Theme.Color.blueSoft
        default: return Theme.Color.green
        }
    }

    var body: some View {
        GeometryReader { geo in
            let w = max(0, min(geo.size.width, geo.size.width * fraction))
            ZStack(alignment: .leading) {
                ZStack {
                    Capsule()
                        .fill(Theme.Color.ink)
                        .offset(y: 3)
                    Capsule()
                        .fill(Theme.Color.card)
                        .overlay(Capsule().strokeBorder(Theme.Color.ink, lineWidth: 2))
                }
                Capsule()
                    .fill(fillColor)
                    .frame(width: w)
                    .padding(3)
                    .mask(
                        Capsule()
                            .frame(width: w)
                            .padding(3)
                    )
                    .overlay(
                        Stripes()
                            .opacity(0.28)
                            .clipShape(Capsule())
                            .frame(width: max(0, w - 6))
                            .padding(.leading, 3)
                    )
                    .animation(.spring(response: 0.45), value: fraction)
            }
        }
        .frame(height: 22)
        .accessibilityLabel(paused ? "Energy paused" : "Energy \(Int(fraction * 100)) percent")
    }
}

private struct Stripes: View {
    var body: some View {
        GeometryReader { geo in
            Path { path in
                let period: CGFloat = 14
                var x: CGFloat = -period
                while x < geo.size.width + period {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x + period / 2, y: geo.size.height))
                    x += period / 2
                }
            }
            .stroke(Color.white, lineWidth: 2)
        }
    }
}

struct DayToken: View {
    enum Style {
        case fed, rest, missed, today, asleep, scheduledRest
    }

    let label: String
    var style: Style

    var body: some View {
        ZStack {
            if style == .today {
                Circle()
                    .strokeBorder(Theme.Color.ink, lineWidth: 2)
                    .padding(-5)
            }
            switch style {
            case .fed:
                Circle()
                    .fill(Theme.Color.orangeSoft)
                    .overlay(Circle().strokeBorder(Theme.Color.ink, lineWidth: 2))
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Theme.Color.ink)
            case .rest:
                Circle()
                    .fill(Theme.Color.paper)
                    .overlay(
                        Circle()
                            .strokeBorder(Theme.Color.restOutline, style: StrokeStyle(lineWidth: 2, dash: [4, 3]))
                    )
                Text(label)
                    .font(CapyFont.nunito(12, .heavy))
                    .foregroundStyle(Theme.Color.textSecondary)
            case .scheduledRest:
                Circle()
                    .fill(Theme.Color.paper)
                    .overlay(Circle().strokeBorder(Theme.Color.restOutline, lineWidth: 2))
                Text(label)
                    .font(CapyFont.nunito(12, .heavy))
                    .foregroundStyle(Theme.Color.textSecondary)
            case .missed:
                Text(label)
                    .font(CapyFont.nunito(12, .heavy))
                    .foregroundStyle(Theme.Color.textSecondary)
            case .today:
                Circle()
                    .strokeBorder(Theme.Color.ink, lineWidth: 2)
                Text(label)
                    .font(CapyFont.nunito(12, .heavy))
            case .asleep:
                Circle()
                    .fill(Theme.Color.asleepGray.opacity(0.3))
                    .overlay(Circle().strokeBorder(Theme.Color.ink, lineWidth: 2))
                Text(label)
                    .font(CapyFont.nunito(12, .heavy))
            }
        }
        .frame(width: 36, height: 36)
    }
}

struct PolaroidFrame<Content: View>: View {
  var rotation: Double = -3
  @ViewBuilder var content: () -> Content

    private let polaroidShape = RoundedRectangle(cornerRadius: 4)

    var body: some View {
        ZStack {
            HardShadowFill(
                shape: polaroidShape,
                fill: Theme.Color.card,
                shadowX: 4,
                shadowY: 6,
                lineWidth: 2.5
            )
            content()
                .padding(.horizontal, 8)
                .padding(.top, 8)
                .padding(.bottom, 28)
        }
        .rotationEffect(.degrees(rotation))
    }
}

struct OnboardingDots: View {
    let step: Int
    let total: Int

    var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<total, id: \.self) { i in
                Circle()
                    .fill(i <= step ? Theme.Color.orange : Theme.Color.paperDot)
                    .overlay(Circle().strokeBorder(Theme.Color.ink, lineWidth: 1.5))
                    .frame(width: 10, height: 10)
            }
        }
        .accessibilityLabel("Step \(step + 1) of \(total)")
    }
}
