import AVFoundation
import UIKit

/// Hosts `AVCaptureVideoPreviewLayer` as the view's root layer so layout stays in sync.
final class CameraPreviewUIView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

    private var rotationCoordinator: Any?

    var previewLayer: AVCaptureVideoPreviewLayer {
        // swiftlint:disable:next force_cast
        layer as! AVCaptureVideoPreviewLayer
    }

    func bind(session: AVCaptureSession, mirrorPreview: Bool) {
        previewLayer.session = session
        previewLayer.videoGravity = .resizeAspectFill

        guard let input = session.inputs.first as? AVCaptureDeviceInput else { return }
        let device = input.device

        if let connection = previewLayer.connection, connection.isVideoMirroringSupported {
            connection.automaticallyAdjustsVideoMirroring = false
            connection.isVideoMirrored = mirrorPreview
        }

        if #available(iOS 17.0, *) {
            rotationCoordinator = AVCaptureDevice.RotationCoordinator(device: device, previewLayer: previewLayer)
        } else if let connection = previewLayer.connection, connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
        }
    }
}
