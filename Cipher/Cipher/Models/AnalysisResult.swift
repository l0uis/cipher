import Foundation
import SwiftData

@Model
final class AnalysisResult {
    var id: UUID
    var createdAt: Date
    var rawJSON: String?

    // Each category stored as JSON string, decoded on demand
    var historyAndOrigins: String?
    var symbolsAndMotifs: String?
    var culturalReferences: String?
    var colorIntelligence: String?
    var materialAndTechnique: String?
    var musicFilmPopCulture: String?
    var contemporaryRelevance: String?

    // Card 3
    var culturalShifts: String?
    var patternProfile: String?

    // Enrichment data from external APIs
    var metMuseumResults: String?
    var europeanaResults: String?

    @Relationship(inverse: \PatternScan.analysisResult)
    var scan: PatternScan?

    init() {
        self.id = UUID()
        self.createdAt = Date()
    }
}
