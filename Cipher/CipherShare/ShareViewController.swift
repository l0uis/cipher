import UIKit
import UniformTypeIdentifiers

class ShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        handleSharedImage()
    }

    private func handleSharedImage() {
        guard let extensionItems = extensionContext?.inputItems as? [NSExtensionItem] else {
            close()
            return
        }

        for item in extensionItems {
            guard let attachments = item.attachments else { continue }

            for provider in attachments {
                if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                    provider.loadItem(forTypeIdentifier: UTType.image.identifier) { [weak self] data, _ in
                        DispatchQueue.main.async {
                            self?.processImage(from: data)
                        }
                    }
                    return
                }
            }
        }

        close()
    }

    private func processImage(from item: NSSecureCoding?) {
        var imageData: Data?

        if let url = item as? URL {
            imageData = try? Data(contentsOf: url)
        } else if let data = item as? Data {
            imageData = data
        } else if let image = item as? UIImage {
            imageData = image.jpegData(compressionQuality: 0.8)
        }

        guard let data = imageData, let image = UIImage(data: data) else {
            close()
            return
        }

        do {
            let resized = image.resizedForCipher()
            guard let jpegData = resized.jpegData(compressionQuality: 0.4) else {
                close()
                return
            }

            let groupID = "group.com.louiscurrie.Cipher"
            guard let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID) else {
                close()
                return
            }

            // Save image
            let imagesDir = container.appendingPathComponent("ScanImages")
            try FileManager.default.createDirectory(at: imagesDir, withIntermediateDirectories: true)

            let fileName = "\(UUID().uuidString).jpg"
            let fileURL = imagesDir.appendingPathComponent(fileName)
            try jpegData.write(to: fileURL)

            // Drop a pending marker for the main app to pick up
            let pendingDir = container.appendingPathComponent("PendingScans")
            try FileManager.default.createDirectory(at: pendingDir, withIntermediateDirectories: true)

            let marker = ["imageFileName": fileName]
            let markerData = try JSONSerialization.data(withJSONObject: marker)
            let markerURL = pendingDir.appendingPathComponent("\(fileName).json")
            try markerData.write(to: markerURL)

            // Open main app
            if let url = URL(string: "cipher://scan") {
                var responder: UIResponder? = self
                while let next = responder?.next {
                    if let application = next as? UIApplication {
                        application.open(url)
                        break
                    }
                    responder = next
                }
            }

            close()
        } catch {
            close()
        }
    }

    private func close() {
        extensionContext?.completeRequest(returningItems: nil)
    }
}

private extension UIImage {
    func resizedForCipher() -> UIImage {
        let maxDimension: CGFloat = 768
        let ratio = min(maxDimension / size.width, maxDimension / size.height)
        if ratio >= 1.0 { return self }
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in draw(in: CGRect(origin: .zero, size: newSize)) }
    }
}
