import AVFoundation
import PhotosUI
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
    @State private var showPhotoPicker = false
    @State private var pickerItem: PhotosPickerItem?

    private var name: String { capys.first?.name ?? "Capy" }

    private var streak: Int {
        capys.first.flatMap { c in
            settingsList.first.map { s in
                SharedStore.snapshot(capy: c, settings: s, feeds: feeds).streak
            }
        } ?? 0
    }

    private var libraryThumbnail: Image? {
        guard let filename = feeds.first?.photoFilename,
              let ui = PhotoStore.load(filename: filename) else { return nil }
        return Image(uiImage: ui)
    }

    var body: some View {
        ZStack {
            if showPreview, let previewImage {
                confirmScreen(previewImage)
            } else {
                PxCameraView(
                    name: name,
                    streak: streak,
                    lastPhotoThumbnail: libraryThumbnail,
                    cameraAvailable: !camera.permissionDenied,
                    onClose: { dismiss() },
                    onShutter: {
                        Task {
                            if let img = await camera.capturePhoto() {
                                previewImage = img
                                showPreview = true
                            }
                        }
                    },
                    onLibrary: { showPhotoPicker = true },
                    onFlip: { camera.flipCamera() },
                    onOpenSettings: {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                ) {
                    CameraPreview(
                        session: camera.session,
                        isRunning: camera.isRunning,
                        mirrorPreview: camera.cameraPosition == .front
                    )
                }
            }
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $pickerItem, matching: .images)
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let ui = UIImage(data: data) {
                    previewImage = ui
                    showPreview = true
                }
                pickerItem = nil
            }
        }
        .task { await camera.configure() }
        .onDisappear { camera.stop() }
    }

    private func confirmScreen(_ image: UIImage) -> some View {
        ZStack {
            PixelBackground(dark: true)
            VStack {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding(12)
                    .pixelBox(fill: Px.cameraPanel, size: .small, outline: .black)
                    .padding()
                Spacer()
                HStack(spacing: 16) {
                    Button("Retake") {
                        showPreview = false
                        previewImage = nil
                    }
                    .font(PxFont.button)
                    .foregroundStyle(Px.card)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .buttonStyle(PixelButtonStyle(fill: Px.card, size: .large, outline: .black))

                    PixelPrimaryButton(title: "Feed \(name)", icon: "pixel_camera") {
                        saveFeed(image)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
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
