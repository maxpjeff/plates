// PxCameraView.swift
// Pixel Camera screen chrome. Pure UI: pass your live camera preview in as `preview`,
// and handle the actions in the closures. No activity chips.

import SwiftUI

struct PxCameraView<Preview: View>: View {
    var name: String
    var streak: Int
    var lastPhotoThumbnail: Image? = nil
    var cameraAvailable: Bool = true

    var onClose: () -> Void
    var onShutter: () -> Void
    var onLibrary: () -> Void        // open PhotosPicker
    var onFlip: () -> Void
    var onOpenSettings: () -> Void   // only used when the camera is denied

    @ViewBuilder var preview: Preview

    var body: some View {
        ZStack {
            PixelBackground(dark: true)

            VStack(spacing: 18) {
                topBar
                previewFrame
                controls
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 20)
        }
    }

    // MARK: Top bar

    private var topBar: some View {
        HStack {
            PixelIconButton(icon: "pixel_close", accessibilityText: "Close", fill: Px.card, outline: .black, action: onClose)
            Spacer()
            Text("Feed \(name)")
                .font(PxFont.make(22, .bold))
                .foregroundStyle(Color.white)
            Spacer()
            StreakPill(streak: streak, dark: true)
        }
    }

    // MARK: Preview

    private var previewFrame: some View {
        ZStack(alignment: .bottomLeading) {
            Px.cameraPreview

            if cameraAvailable {
                preview
            } else {
                deniedCard
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            ViewfinderCorners()
                .allowsHitTesting(false)

            HStack(alignment: .bottom, spacing: 4) {
                CapySprite(status: .recovering, maxHeight: 108, bobs: false)
                    .fixedSize(horizontal: true, vertical: false)
                SpeechBubble(text: "Show me what you're up to")
                    .padding(.bottom, 56)
            }
            .padding(.leading, 10)
            .padding(.bottom, 4)
            .allowsHitTesting(false)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .pixelBox(fill: Px.cameraPreview, size: .flat, outline: .black)
    }

    private var deniedCard: some View {
        VStack(spacing: 12) {
            Text("Camera's off.")
                .font(PxFont.make(22, .bold))
            Text("Turn it on in Settings, or pick a photo.")
                .font(PxFont.body)
                .multilineTextAlignment(.center)
            Button(action: onOpenSettings) {
                Text("Open Settings")
                    .font(PxFont.make(18, .bold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
            }
            .buttonStyle(PixelButtonStyle(fill: Px.orange, size: .small))
        }
        .foregroundStyle(Px.ink)
        .padding(18)
        .pixelBox(fill: Px.card, size: .large)
        .padding(28)
    }

    // MARK: Controls

    private var controls: some View {
        HStack {
            // Photo library (bottom-left)
            Button(action: onLibrary) {
                ZStack {
                    Px.cameraPreview
                    if let lastPhotoThumbnail {
                        lastPhotoThumbnail.resizable().scaledToFill()
                    } else {
                        PixelIcon("pixel_photos", size: 32)
                    }
                }
                .frame(width: 46, height: 46)
                .clipped()
            }
            .buttonStyle(PixelButtonStyle(fill: Px.cameraPreview, size: .small, outline: .black))
            .accessibilityLabel("Choose a photo")

            Spacer()

            // Shutter
            Button(action: onShutter) {
                Rectangle()
                    .fill(Px.orange)
                    .frame(width: 52, height: 52)
                    .pixelBox(fill: Px.orange, size: .flat, outline: .black)
                    .frame(width: 76, height: 76)
            }
            .buttonStyle(PixelButtonStyle(fill: Px.card, size: .large, outline: .black))
            .accessibilityLabel("Take photo")

            Spacer()

            PixelIconButton(icon: "pixel_flip", accessibilityText: "Flip camera", fill: Px.cameraPanel, side: 40, outline: .black, action: onFlip)
        }
        .padding(.horizontal, 22)
    }
}

/// Four white L-shaped corners, 6pt thick, 36pt long, 18pt in from the edges.
struct ViewfinderCorners: View {
    var inset: CGFloat = 18
    var length: CGFloat = 36
    var thickness: CGFloat = 6

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack(alignment: .topLeading) {
                corner.offset(x: inset, y: inset)
                corner.rotationEffect(.degrees(90)).offset(x: w - inset - length, y: inset)
                corner.rotationEffect(.degrees(180)).offset(x: w - inset - length, y: h - inset - length)
                corner.rotationEffect(.degrees(270)).offset(x: inset, y: h - inset - length)
            }
        }
    }

    private var corner: some View {
        ZStack(alignment: .topLeading) {
            Rectangle().fill(Px.card).frame(width: length, height: thickness)
            Rectangle().fill(Px.card).frame(width: thickness, height: length)
        }
        .frame(width: length, height: length, alignment: .topLeading)
    }
}

#Preview("Camera") {
    PxCameraView(
        name: "Biscuit",
        streak: 12,
        onClose: {}, onShutter: {}, onLibrary: {}, onFlip: {}, onOpenSettings: {}
    ) {
        Color.clear
    }
}

#Preview("Camera – denied") {
    PxCameraView(
        name: "Biscuit",
        streak: 12,
        cameraAvailable: false,
        onClose: {}, onShutter: {}, onLibrary: {}, onFlip: {}, onOpenSettings: {}
    ) {
        Color.clear
    }
}
