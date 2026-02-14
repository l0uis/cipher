import UIKit
import Foundation

actor ImageStorageService {
    static let shared = ImageStorageService()

    private var imagesDirectory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent(AppConstants.Image.scanImageDirectory)
    }

    func saveImage(_ image: UIImage) throws -> String {
        try FileManager.default.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)

        let resized = image.resizedToMaxDimension(AppConstants.Image.maxImageDimension)
        guard let data = resized.jpegData(compressionQuality: AppConstants.Image.jpegCompressionQuality) else {
            throw ImageStorageError.compressionFailed
        }

        let fileName = "\(UUID().uuidString).jpg"
        let fileURL = imagesDirectory.appendingPathComponent(fileName)
        try data.write(to: fileURL)
        return fileName
    }

    func loadImage(fileName: String) -> UIImage? {
        let fileURL = imagesDirectory.appendingPathComponent(fileName)
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }

    func loadImageData(fileName: String) -> Data? {
        let fileURL = imagesDirectory.appendingPathComponent(fileName)
        return try? Data(contentsOf: fileURL)
    }

    func deleteImage(fileName: String) {
        let fileURL = imagesDirectory.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: fileURL)
    }
}

enum ImageStorageError: LocalizedError {
    case compressionFailed

    var errorDescription: String? {
        switch self {
        case .compressionFailed:
            return "Failed to compress image"
        }
    }
}

extension UIImage {
    func resizedToMaxDimension(_ maxDimension: CGFloat) -> UIImage {
        let ratio = min(maxDimension / size.width, maxDimension / size.height)
        if ratio >= 1.0 { return self }
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in draw(in: CGRect(origin: .zero, size: newSize)) }
    }
}
