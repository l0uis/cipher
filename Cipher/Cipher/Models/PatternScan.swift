import Foundation
import SwiftData

@Model
final class PatternScan {
    var id: UUID
    var capturedAt: Date
    var imageFileName: String
    var patternName: String?
    var patternOrigin: String?
    var analysisStatus: String
    var analysisStage: String?
    var errorMessage: String?

    @Relationship(deleteRule: .cascade)
    var analysisResult: AnalysisResult?

    init(imageFileName: String) {
        self.id = UUID()
        self.capturedAt = Date()
        self.imageFileName = imageFileName
        self.analysisStatus = "pending"
    }
}
