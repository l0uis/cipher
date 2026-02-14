import SwiftUI
import PhotosUI
import SwiftData

@Observable
class CaptureViewModel {
    var selectedPhotoItem: PhotosPickerItem?
    var capturedImage: UIImage?
    var isProcessing = false
    var showCamera = false
    var errorMessage: String?

    func processSelectedPhoto() async {
        guard let item = selectedPhotoItem else { return }
        isProcessing = true
        defer { isProcessing = false }

        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else {
            errorMessage = "Failed to load selected photo"
            return
        }
        capturedImage = image
    }

    func startAnalysis(image: UIImage, modelContext: ModelContext) async -> PatternScan? {
        isProcessing = true
        defer { isProcessing = false }

        do {
            let fileName = try await ImageStorageService.shared.saveImage(image)
            let scan = PatternScan(imageFileName: fileName)
            scan.analysisStatus = "analyzing"
            modelContext.insert(scan)
            try modelContext.save()

            guard let imageData = await ImageStorageService.shared.loadImageData(fileName: fileName) else {
                throw ImageStorageError.compressionFailed
            }

            Task.detached {
                await AnalysisOrchestrator.shared.performFullAnalysis(
                    imageData: imageData,
                    scan: scan,
                    modelContext: modelContext
                )
            }

            return scan
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func reset() {
        selectedPhotoItem = nil
        capturedImage = nil
        isProcessing = false
        showCamera = false
        errorMessage = nil
    }
}
