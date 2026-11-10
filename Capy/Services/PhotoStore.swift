import UIKit

enum PhotoStore {
    static func saveJPEG(_ image: UIImage) throws -> String {
        guard let dir = SharedStore.photosDirectory() else {
            throw NSError(domain: "PhotoStore", code: 1, userInfo: [NSLocalizedDescriptionKey: "No app group"])
        }
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let name = UUID().uuidString + ".jpg"
        let url = dir.appendingPathComponent(name)
        let scaled = scale(image, maxLongEdge: 1600)
        guard let data = scaled.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "PhotoStore", code: 2)
        }
        try data.write(to: url, options: .atomic)
        return name
    }

    static func load(filename: String) -> UIImage? {
        guard let dir = SharedStore.photosDirectory() else { return nil }
        let url = dir.appendingPathComponent(filename)
        return UIImage(contentsOfFile: url.path)
    }

    static func delete(filename: String) {
        guard let dir = SharedStore.photosDirectory() else { return }
        try? FileManager.default.removeItem(at: dir.appendingPathComponent(filename))
    }

    private static func scale(_ image: UIImage, maxLongEdge: CGFloat) -> UIImage {
        let w = image.size.width
        let h = image.size.height
        let long = max(w, h)
        guard long > maxLongEdge else { return image }
        let scale = maxLongEdge / long
        let newSize = CGSize(width: w * scale, height: h * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
