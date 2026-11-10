import AVFoundation
import SwiftData
import SwiftUI

struct CameraFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(CapyAppState.self) private var appState

    @Query private var capys: [Capybara]
    @Query private var settingsList: [CapySettings]
    @Query(sort: \Feed.takenAt, order: .reverse) private var feeds: [Feed]

    @State private var camera = CameraService()
    @State private var previewImage: UIImage?
    @State private var showPreview = false

    private var name: String { capys.first?.name ?? "Capy" }

    var body: some View {
        ZStack {
            Theme.Color.cameraBg.ignoresSafeArea()
            if camera.permissionDenied {
                permissionView
            } else if showPreview, let previewImage {
                previewScreen(previewImage)
            } else {
                liveCamera
            }
        }
        .task { await camera.configure() }
        .onDisappear { camera.stop() }
    }

    private var liveCamera: some View {
        VStack(spacing: 0) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                }
                Spacer()
                Text("Feed \(name)")
                    .font(CapyFont.fredoka(22))
                    .foregroundStyle(.white)
                Spacer()
                streakPill
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 12)

            GeometryReader { geo in
                CameraPreview(
                    session: camera.session,
                    isRunning: camera.isRunning,
                    mirrorPreview: camera.cameraPosition == .front
                )
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay {
                        ViewfinderBrackets()
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 420)
            .padding(.horizontal, 16)

            Spacer(minLength: 8)

            HStack(spacing: 40) {
                Color.clear.frame(width: 52, height: 52)
                Button {
                    Task {
                        if let img = await camera.capturePhoto() {
                            previewImage = img
                            showPreview = true
                        }
                    }
                } label: {
                    ZStack {
                        Circle().strokeBorder(.white, lineWidth: 4).frame(width: 76, height: 76)
                        Circle().fill(Theme.Color.orange).frame(width: 60, height: 60)
                    }
                }
                .accessibilityLabel("Take photo")
                Button { camera.flipCamera() } label: {
                    Image(systemName: "arrow.triangle.2.circlepath.camera")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 52, height: 52)
                }
                .accessibilityLabel("Flip camera")
            }
            .padding(.vertical, 28)
        }
    }

    private var streakPill: some View {
        let streak = capys.first.flatMap { c in
            settingsList.first.map { s in
                SharedStore.snapshot(capy: c, settings: s, feeds: feeds).streak
            }
        } ?? 0
        return CapyPill(title: "\(streak)", icon: "flame.fill")
    }

    private func previewScreen(_ image: UIImage) -> some View {
        VStack {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding()
            Spacer()
            HStack(spacing: 16) {
                Button("Retake") {
                    showPreview = false
                    previewImage = nil
                }
                .font(CapyFont.fredoka(20))
                .foregroundStyle(.white)
                Button("Feed") {
                    saveFeed(image)
                }
                .font(CapyFont.fredoka(20))
                .foregroundStyle(Theme.Color.ink)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Capsule().fill(Theme.Color.orange))
            }
            .padding(.bottom, 40)
        }
    }

    private var permissionView: some View {
        VStack(spacing: 16) {
            Text("Camera access is needed to feed your capybara.")
                .font(CapyFont.nunito(16))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            CapyPrimaryButton(title: "Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .padding(.horizontal, 24)
            Button("Close") { dismiss() }
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding()
    }

    private func saveFeed(_ image: UIImage) {
        guard let capy = capys.first, let settings = settingsList.first else { return }
        do {
            let result = try FeedService.recordFeed(image: image, context: context, capy: capy, settings: settings)
            appState.lastFedImage = image
            appState.lastFedStreakDay = result.streakDay
            appState.lastFedWasNewStreak = result.newStreak
            appState.showCamera = false
            appState.showFed = true
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        } catch {
            dismiss()
        }
    }
}

private struct ViewfinderBrackets: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let len: CGFloat = 24
            Path { p in
                p.move(to: CGPoint(x: 20, y: 20 + len))
                p.addLine(to: CGPoint(x: 20, y: 20))
                p.addLine(to: CGPoint(x: 20 + len, y: 20))
                p.move(to: CGPoint(x: w - 20 - len, y: 20))
                p.addLine(to: CGPoint(x: w - 20, y: 20))
                p.addLine(to: CGPoint(x: w - 20, y: 20 + len))
                p.move(to: CGPoint(x: 20, y: h - 20 - len))
                p.addLine(to: CGPoint(x: 20, y: h - 20))
                p.addLine(to: CGPoint(x: 20 + len, y: h - 20))
            }
            .stroke(Color.white.opacity(0.8), lineWidth: 2)
        }
        .allowsHitTesting(false)
    }
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    var isRunning: Bool
    var mirrorPreview: Bool

    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.backgroundColor = .black
        view.bind(session: session, mirrorPreview: mirrorPreview)
        return view
    }

    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        uiView.bind(session: session, mirrorPreview: mirrorPreview)
        _ = isRunning
    }
}

#Preview {
    CameraFlowView()
        .environment(CapyAppState())
}
