import Foundation
import SwiftData

actor AnalysisOrchestrator {
    static let shared = AnalysisOrchestrator()

    func performFullAnalysis(imageData: Data, scan: PatternScan, modelContext: ModelContext) async {
        do {
            await setStage("Uploading image...", scan: scan, context: modelContext)

            let analysis = try await ClaudeAPIService.shared.analyzePattern(
                imageData: imageData,
                onPolling: { attempt in
                    let stages = [
                        "Reading the pattern...",
                        "Tracing cultural origins...",
                        "Decoding symbols & motifs...",
                        "Analyzing color language...",
                        "Researching material history...",
                        "Scanning pop culture references...",
                        "Assessing contemporary relevance..."
                    ]
                    let index = min(attempt / 2, stages.count - 1)
                    await self.setStage(stages[index], scan: scan, context: modelContext)
                }
            )

            let result = AnalysisResult()
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase

            result.historyAndOrigins = encodeToString(analysis.historyAndOrigins, encoder: encoder)
            result.symbolsAndMotifs = encodeToString(analysis.symbolsAndMotifs, encoder: encoder)
            result.culturalReferences = encodeToString(analysis.culturalReferences, encoder: encoder)
            result.colorIntelligence = encodeToString(analysis.colorIntelligence, encoder: encoder)
            result.materialAndTechnique = encodeToString(analysis.materialAndTechnique, encoder: encoder)
            result.musicFilmPopCulture = encodeToString(analysis.musicFilmPopCulture, encoder: encoder)
            result.contemporaryRelevance = encodeToString(analysis.contemporaryRelevance, encoder: encoder)
            if let shifts = analysis.culturalShifts {
                result.culturalShifts = encodeToString(shifts, encoder: encoder)
            }
            if let profile = analysis.patternProfile {
                result.patternProfile = encodeToString(profile, encoder: encoder)
            }

            await MainActor.run {
                scan.patternName = analysis.patternName
                scan.patternOrigin = analysis.patternOrigin
                scan.analysisResult = result
                scan.analysisStatus = "completed"
                scan.analysisStage = nil
                try? modelContext.save()
            }

        } catch {
            await MainActor.run {
                scan.analysisStatus = "failed"
                scan.analysisStage = nil
                scan.errorMessage = error.localizedDescription
                try? modelContext.save()
            }
        }
    }

    private func setStage(_ stage: String, scan: PatternScan, context: ModelContext) async {
        await MainActor.run {
            scan.analysisStage = stage
            try? context.save()
        }
    }

    private func encodeToString<T: Encodable>(_ value: T, encoder: JSONEncoder) -> String? {
        guard let data = try? encoder.encode(value) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
