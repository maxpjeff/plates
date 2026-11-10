// PxComponents.swift
// Reusable pixel-style building blocks. Every screen is built ONLY from these.
// Add this file to BOTH the app target and the widget target.

import SwiftUI

// MARK: - Graph-paper grid

/// Solid color with 1pt grid lines every 8pt. Used for app backgrounds and scene areas.
struct PixelGrid: View {
    var background: Color
    var line: Color
    var spacing: CGFloat = Px.gridSpacing

    var body: some View {
        Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(background))
            var lines = Path()
            var x: CGFloat = 0
            while x <= size.width {
                lines.addRect(CGRect(x: x, y: 0, width: 1, height: size.height))
                x += spacing
            }
            var y: CGFloat = 0
            while y <= size.height {
                lines.addRect(CGRect(x: 0, y: y, width: size.width, height: 1))
                y += spacing
            }
            context.fill(lines, with: .color(line))
        }
    }
}

/// Full-screen app background. Put it at the bottom of every screen's ZStack.
struct PixelBackground: View {
    var dark: Bool = false

    var body: some View {
        PixelGrid(
            background: dark ? Px.cameraBg : Px.paper,
            line: dark ? Px.cameraGrid : Px.gridLine
        )
        .ignoresSafeArea()
    }
}

// MARK: - PixelBox (the core of the whole look)

/// side = thickness of the ink bar on each side, drop = extra ink below the bottom edge.
enum PixelBoxSize {
    case large    // cards, primary buttons, stat cards
    case small    // pills with shadow, icon buttons, polaroids, speech bubbles
    case flat     // status pills (no drop shadow)
    case widget   // inside widgets (thin, no drop shadow)

    var side: CGFloat {
        switch self {
        case .large: return 4
        case .small: return 3
        case .flat: return 3
        case .widget: return 2
        }
    }

    var drop: CGFloat {
        switch self {
        case .large: return 6
        case .small: return 3
        case .flat: return 0
        case .widget: return 0
        }
    }
}

/// Draws the fill, then 4 ink bars OUTSIDE the edges (corners left empty = notched pixel corners),
/// with the bottom bar extended by `drop` as a blocky shadow. Padding is added so the bars are
/// part of the layout and never overlap neighbors. NEVER replace this with .border or cornerRadius.
struct PixelBoxModifier: ViewModifier {
    var fill: Color
    var size: PixelBoxSize
    var pressed: Bool = false
    var outline: Color = Px.ink

    func body(content: Content) -> some View {
        let s = size.side
        let d = pressed ? min(2, size.drop) : size.drop
        return content
            .background(fill)
            .background {
                GeometryReader { geo in
                    let w = geo.size.width
                    let h = geo.size.height
                    ZStack(alignment: .topLeading) {
                        Rectangle().fill(outline).frame(width: w, height: s).offset(x: 0, y: -s)      // top
                        Rectangle().fill(outline).frame(width: w, height: s + d).offset(x: 0, y: h)   // bottom + drop
                        Rectangle().fill(outline).frame(width: s, height: h).offset(x: -s, y: 0)      // left
                        Rectangle().fill(outline).frame(width: s, height: h).offset(x: w, y: 0)       // right
                    }
                }
            }
            .padding(.horizontal, s)
            .padding(.top, s)
            .padding(.bottom, s + size.drop)
    }
}

extension View {
    func pixelBox(fill: Color, size: PixelBoxSize = .large, outline: Color = Px.ink) -> some View {
        modifier(PixelBoxModifier(fill: fill, size: size, outline: outline))
    }
}

// MARK: - Buttons

/// Any button in the app. Pressed = content drops down while the shadow shrinks, plus a light haptic.
struct PixelButtonStyle: ButtonStyle {
    var fill: Color = Px.orange
    var size: PixelBoxSize = .large
    var outline: Color = Px.ink

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        return configuration.label
            .foregroundStyle(Px.ink)
            .modifier(PixelBoxModifier(fill: fill, size: size, pressed: pressed, outline: outline))
            .offset(y: pressed ? max(0, size.drop - 2) : 0)
            .onChange(of: pressed) { _, isPressed in
                #if canImport(UIKit)
                if isPressed { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
                #endif
            }
    }
}

/// The big orange button at the bottom of screens.
struct PixelPrimaryButton: View {
    let title: String
    var icon: String? = "pixel_camera"
    var fill: Color = Px.orange
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if let icon { PixelIcon(icon, size: 32) }
                Text(title)
                    .font(PxFont.button)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, minHeight: 56)
            .padding(.horizontal, 12)
        }
        .buttonStyle(PixelButtonStyle(fill: fill, size: .large))
    }
}

/// Small square button with one icon (history, settings, back, close, flip).
struct PixelIconButton: View {
    let icon: String
    let accessibilityText: String
    var fill: Color = Px.card
    var side: CGFloat = 38
    var outline: Color = Px.ink
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            PixelIcon(icon, size: 24)
                .frame(width: side, height: side)
        }
        .buttonStyle(PixelButtonStyle(fill: fill, size: .small, outline: outline))
        .accessibilityLabel(accessibilityText)
    }
}

// MARK: - Icons & sprites

/// Pixel icons from the asset catalog (pixel_flame, pixel_gear, pixel_camera, pixel_calendar,
/// pixel_back, pixel_close, pixel_check, pixel_flip, pixel_photos). Use sizes 16, 24, 32 or 48.
struct PixelIcon: View {
    let name: String
    var size: CGFloat

    init(_ name: String, size: CGFloat = 24) {
        self.name = name
        self.size = size
    }

    var body: some View {
        Image(name)
            .interpolation(.none)
            .resizable()
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

/// The capybara. Always fits inside maxWidth x maxHeight without cropping, keeps pixels sharp,
/// and does a 2-step bob when Locked in.
struct CapySprite: View {
    let status: PxStatus
    var maxHeight: CGFloat
    var maxWidth: CGFloat? = nil
    var bobs: Bool = true

    @State private var up = false

    var body: some View {
        Image(status.sprite)
            .interpolation(.none)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: maxWidth ?? .infinity, maxHeight: maxHeight)
            .offset(y: up ? -2 : 0)
            .task(id: status) {
                up = false
                guard bobs, status == .lockedIn else { return }
                while !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    up.toggle()   // no animation on purpose: stepped movement
                }
            }
            .accessibilityLabel(Text(status.label.capitalized))
    }
}

/// Stepped "pop" (1.0 -> 1.08 -> 0.96 -> 1.0) whenever `trigger` changes and on first appear.
struct SteppedPop: ViewModifier {
    var trigger: AnyHashable
    @State private var scale: CGFloat = 1

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .task(id: trigger) {
                for s in [0.85, 1.08, 0.96, 1.0] as [CGFloat] {
                    scale = s
                    try? await Task.sleep(nanoseconds: 80_000_000)
                }
            }
    }
}

extension View {
    func steppedPop(trigger: AnyHashable) -> some View { modifier(SteppedPop(trigger: trigger)) }
}

// MARK: - Scene area (colored grid behind the capybara)

struct PixelScene<Content: View>: View {
    let status: PxStatus
    var height: CGFloat
    var showSparkles: Bool = true
    @ViewBuilder var content: Content

    var body: some View {
        ZStack(alignment: .bottom) {
            PixelGrid(background: status.sceneColor, line: status.sceneGrid)
            content
                .padding(.bottom, 10)
        }
        .overlay(alignment: .topLeading) {
            if showSparkles {
                ZStack(alignment: .topLeading) {
                    Rectangle().fill(Px.yellow).frame(width: 8, height: 8).offset(x: 12, y: 12)
                    Rectangle().fill(Px.yellow).frame(width: 8, height: 8).offset(x: 20, y: 20)
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            if showSparkles {
                Rectangle().fill(Color.white).frame(width: 8, height: 8).offset(x: -20, y: 12)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipped()
    }
}

// MARK: - Pills

struct StatusPill: View {
    let status: PxStatus
    var compact: Bool = false

    var body: some View {
        Text(status.label)
            .font(compact ? PxFont.make(13, .bold) : PxFont.pill)
            .foregroundStyle(status.pillText)
            .padding(.horizontal, compact ? 6 : 10)
            .padding(.vertical, compact ? 1 : 3)
            .pixelBox(fill: status.pillColor, size: compact ? .widget : .flat)
    }
}

struct StreakPill: View {
    let streak: Int
    var compact: Bool = false
    var dark: Bool = false

    var body: some View {
        HStack(spacing: compact ? 3 : 6) {
            PixelIcon("pixel_flame", size: compact ? 12 : 18)
            Text("\(streak)")
                .font(compact ? PxFont.make(14, .bold) : PxFont.make(20, .bold))
                .foregroundStyle(dark ? Px.yellow : Px.ink)
        }
        .padding(.horizontal, compact ? 6 : 10)
        .frame(height: compact ? 20 : 32)
        .pixelBox(
            fill: dark ? Px.cameraPanel : Px.yellow,
            size: compact ? .widget : .small,
            outline: dark ? .black : Px.ink
        )
    }
}

// MARK: - Segmented "Today" bar

struct SegmentedBar: View {
    var fraction: Double        // 0...1
    var color: Color
    var segments: Int = 12
    var segmentHeight: CGFloat = 16
    var boxSize: PixelBoxSize = .small

    private var filled: Int {
        guard fraction > 0 else { return 0 }
        return min(segments, Int((fraction * Double(segments)).rounded(.up)))
    }

    var body: some View {
        HStack(spacing: segments > 8 ? 3 : 2) {
            ForEach(0..<segments, id: \.self) { i in
                Rectangle()
                    .fill(i < filled ? color : Px.segmentEmpty)
                    .frame(height: segmentHeight)
            }
        }
        .padding(boxSize == .widget ? 2 : 4)
        .pixelBox(fill: Px.card, size: boxSize)
    }
}

// MARK: - Day token (squares, never circles)

struct DayToken: View {
    let kind: PxDayKind
    var side: CGFloat = 32
    var number: Int? = nil
    var border: CGFloat = 3

    var body: some View {
        ZStack {
            switch kind {
            case .posted:
                Rectangle().fill(Px.orangeSoft)
                    .overlay(Rectangle().strokeBorder(Px.ink, lineWidth: border))
            case .todayPosted:
                Rectangle().fill(Px.orange)
                    .overlay(Rectangle().strokeBorder(Px.ink, lineWidth: border))
            case .today:
                Rectangle().fill(Px.card)
                    .overlay(Rectangle().strokeBorder(Px.ink, lineWidth: border))
            case .rest:
                Rectangle().strokeBorder(Px.restOutline, style: StrokeStyle(lineWidth: border, dash: [4, 3]))
            case .missed:
                Rectangle().fill(Px.pinkSoft)
            case .future:
                Color.clear
            }

            if let number {
                Text("\(number)")
                    .font(PxFont.make(side > 30 ? 15 : 12, .bold))
                    .foregroundStyle(numberColor)
            } else if kind == .posted || kind == .todayPosted {
                PixelIcon("pixel_check", size: side * 0.5)
            }
        }
        .frame(width: side, height: side)
        .overlay {
            if kind == .today || kind == .todayPosted {
                Rectangle()
                    .stroke(Px.ink, lineWidth: border)
                    .padding(-(border * 2))
            }
        }
    }

    private var numberColor: Color {
        switch kind {
        case .missed: return Px.pinkText
        case .rest: return Px.textSecondary
        case .future: return Px.textMuted
        default: return Px.ink
        }
    }
}

// MARK: - Cards

struct StatCard: View {
    let label: String       // shown in caps
    let value: String
    let fill: Color
    let labelColor: Color
    var valueSize: CGFloat = 30

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(label.uppercased())
                .font(PxFont.make(14, .semibold))
                .foregroundStyle(labelColor)
            Text(value)
                .font(PxFont.make(valueSize, .bold))
                .foregroundStyle(Px.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .pixelBox(fill: fill, size: .large)
    }
}

struct SpeechBubble: View {
    let text: String

    var body: some View {
        Text(text)
            .font(PxFont.make(16, .semibold))
            .foregroundStyle(Px.ink)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .pixelBox(fill: Px.card, size: .small, outline: .black)
    }
}

/// Photo card. `photo` nil = placeholder color.
struct PolaroidView: View {
    var photo: Image?
    var leftText: String
    var rightText: String? = nil
    var width: CGFloat = 156
    var photoHeight: CGFloat = 140
    var size: PixelBoxSize = .large

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Px.photoPlaceholder
                if let photo {
                    photo.resizable().scaledToFill()
                }
            }
            .frame(width: width, height: photoHeight)
            .clipped()

            HStack {
                Text(leftText.uppercased())
                Spacer(minLength: 4)
                if let rightText { Text(rightText.uppercased()) }
            }
            .font(PxFont.make(13, .semibold))
            .foregroundStyle(Px.textSecondary)
            .frame(width: width)
        }
        .padding(8)
        .pixelBox(fill: Px.card, size: size)
    }
}
