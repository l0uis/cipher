import SwiftUI
import SwiftData

@Observable
class HomeViewModel {
    var showingCapture = false
    var navigateToScan: PatternScan?

    func deleteScan(_ scan: PatternScan, modelContext: ModelContext) {
        Task {
            await ImageStorageService.shared.deleteImage(fileName: scan.imageFileName)
        }
        modelContext.delete(scan)
    }
}
