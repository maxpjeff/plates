import SwiftUI

enum MascotStyle {
    /// Small sticker with ink border and hard shadow.
    case full
    /// Home hero — illustration only, no extra frame.
    case hero
    case silhouette
}

struct MascotView: View {
    var phase: CapyMascotPhase
    var size: CGFloat
    var style: MascotStyle = .full

    init(phase: CapyMascotPhase, size: CGFloat, style: MascotStyle = .full) {
        self.phase = phase
        self.size = size
        self.style = style
    }

    /// Convenience for fed/camera specials and previews.
    init(state: CapyState, lastFeedAt: Date? = nil, size: CGFloat, style: MascotStyle = .full) {
        switch state {
        case .cheering:
            self.phase = .lockedIn
        case .peeking:
            self.phase = CapyMascotPhase.phase(lastFeedAt: lastFeedAt)
        case .restDay:
            self.phase = CapyMascotPhase.phase(lastFeedAt: lastFeedAt)
        case .lockedIn:
            self.phase = .lockedIn
        case .chilling:
            self.phase = .recovering
        case .couch:
            self.phase = .couch
        case .asleep:
            self.phase = .streakLost
        }
        self.size = size
        self.style = style
    }

    init(lastFeedAt: Date?, at: Date = CapyClock.now(), size: CGFloat, style: MascotStyle = .full) {
        self.phase = CapyMascotPhase.phase(lastFeedAt: lastFeedAt, at: at)
        self.size = size
        self.style = style
    }

    private var bob: CGFloat {
        phase == .lockedIn ? 2 : 0
    }

    private let cornerRatio: CGFloat = 0.14

    var body: some View {
        let corner = size * cornerRatio
        Group {
            switch style {
            case .hero:
                image
                    .scaledToFit()
                    .frame(maxWidth: size, maxHeight: size)
            case .full, .silhouette:
                ZStack {
                    if style == .full {
                        RoundedRectangle(cornerRadius: corner, style: .continuous)
                            .fill(Theme.Color.ink)
                            .frame(width: size, height: size)
                            .offset(y: Theme.Layout.hardShadow)
                    }
                    image
                        .frame(width: size, height: size)
                        .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
                        .overlay {
                            if style == .full {
                                RoundedRectangle(cornerRadius: corner, style: .continuous)
                                    .strokeBorder(Theme.Color.ink, lineWidth: Theme.Layout.border)
                            }
                        }
                }
                .frame(width: size, height: size)
            }
        }
        .modifier(BobModifier(active: phase == .lockedIn && (style == .full || style == .hero), amount: bob))
        .accessibilityLabel(Text("Capybara, \(phase.statusLabel)"))
    }

    @ViewBuilder
    private var image: some View {
        let base = Image(phase.imageName).resizable()

        switch style {
        case .hero:
            base.scaledToFit()
        case .silhouette:
            base
                .scaledToFill()
                .saturation(0)
                .contrast(1.15)
                .brightness(-0.15)
                .widgetAccentable()
        case .full:
            base.scaledToFill()
        }
    }
}

private struct BobModifier: ViewModifier {
    let active: Bool
    let amount: CGFloat
    @State private var up = false

    func body(content: Content) -> some View {
        content
            .offset(y: active ? (up ? -amount : amount) : 0)
            .onAppear {
                guard active else { return }
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    up.toggle()
                }
            }
    }
}

#Preview("Phases") {
    ScrollView {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 16) {
            ForEach(CapyMascotPhase.allCases, id: \.self) { p in
                VStack {
                    MascotView(phase: p, size: 110)
                    Text(p.statusLabel).font(CapyFont.nunito(12))
                }
            }
        }
        .padding()
    }
    .background(PaperBackground())
}
