import AVFoundation
import UIKit

@Observable
final class CameraService: NSObject {
    let session = AVCaptureSession()
    private let output = AVCapturePhotoOutput()
    private let sessionQueue = DispatchQueue(label: "com.maxpjeff.capy.camera.session")
    private var continuation: CheckedContinuation<UIImage?, Never>?

    var permissionDenied = false
    var isRunning = false
    private(set) var cameraPosition: AVCaptureDevice.Position = .back

    /// Session queue–owned position at shutter time (front → mirror capture to match preview).
    private var captureDevicePosition: AVCaptureDevice.Position = .back

    func configure() async {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            await setupSession()
        case .notDetermined:
            let ok = await AVCaptureDevice.requestAccess(for: .video)
            if ok { await setupSession() } else { permissionDenied = true }
        default:
            permissionDenied = true
        }
    }

    @MainActor
    private func setupSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.session.beginConfiguration()
            self.session.sessionPreset = .high
            self.session.inputs.forEach { self.session.removeInput($0) }
            guard
                let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                let input = try? AVCaptureDeviceInput(device: device),
                self.session.canAddInput(input)
            else {
                self.session.commitConfiguration()
                return
            }
            self.session.addInput(input)
            if self.session.outputs.isEmpty, self.session.canAddOutput(self.output) {
                self.session.addOutput(self.output)
            }
            self.session.commitConfiguration()
            self.captureDevicePosition = .back
            self.session.startRunning()
            DispatchQueue.main.async {
                self.isRunning = true
                self.cameraPosition = .back
            }
        }
    }

    func flipCamera() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            guard let current = self.session.inputs.first as? AVCaptureDeviceInput else { return }
            let pos: AVCaptureDevice.Position = current.device.position == .back ? .front : .back
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: pos),
                  let input = try? AVCaptureDeviceInput(device: device) else { return }
            self.session.beginConfiguration()
            self.session.removeInput(current)
            if self.session.canAddInput(input) { self.session.addInput(input) }
            self.session.commitConfiguration()
            self.captureDevicePosition = pos
            DispatchQueue.main.async {
                self.cameraPosition = pos
            }
        }
    }

    func capturePhoto() async -> UIImage? {
        await withCheckedContinuation { cont in
            continuation = cont
            sessionQueue.async { [weak self] in
                guard let self else {
                    cont.resume(returning: nil)
                    return
                }
                let settings = AVCapturePhotoSettings()
                if let connection = self.output.connection(with: .video), connection.isVideoOrientationSupported {
                    connection.videoOrientation = .portrait
                }
                if #available(iOS 17.0, *),
                   let connection = self.output.connection(with: .video),
                   connection.isVideoRotationAngleSupported(90) {
                    connection.videoRotationAngle = 90
                }
                self.output.capturePhoto(with: settings, delegate: self)
            }
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            self?.session.stopRunning()
            DispatchQueue.main.async { self?.isRunning = false }
        }
    }
}

extension CameraService: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(), let image = UIImage(data: data) else {
            continuation?.resume(returning: nil)
            continuation = nil
            return
        }
        let delivered = captureDevicePosition == .front ? image.mirroredLikePreview() : image
        continuation?.resume(returning: delivered)
        continuation = nil
    }
}

private extension UIImage {
    /// Matches the horizontally mirrored front-camera preview.
    func mirroredLikePreview() -> UIImage {
        UIGraphicsImageRenderer(size: size).image { ctx in
            ctx.cgContext.translateBy(x: size.width, y: 0)
            ctx.cgContext.scaleBy(x: -1, y: 1)
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
