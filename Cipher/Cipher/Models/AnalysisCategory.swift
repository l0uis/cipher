import Foundation

// MARK: - Umbrella response from Claude

struct PatternAnalysisResponse: Codable {
    let patternName: String
    let patternOrigin: String
    let confidenceNote: String
    let historyAndOrigins: HistoryOrigins
    let symbolsAndMotifs: SymbolsMotifs
    let culturalReferences: CulturalRefs
    let colorIntelligence: ColorIntel
    let materialAndTechnique: MaterialTech
    let musicFilmPopCulture: PopCultureRefs
    let contemporaryRelevance: ContemporaryRel
    var culturalShifts: CulturalShifts? = nil
    var patternProfile: [PatternProfileAttribute]? = nil
}

// MARK: - History & Origins

struct HistoryOrigins: Codable {
    let summary: String
    let originPeriod: String
    let geographicOrigin: String
    let culturalOrigin: String
    let evolutionTimeline: [TimelineEntry]
    let tradeAndColonialInfluences: [String]
    let revivalMoments: [String]
}

struct TimelineEntry: Codable, Identifiable {
    let period: String
    let description: String

    var id: String { period }
}

// MARK: - Symbols & Motifs

struct SymbolsMotifs: Codable {
    let summary: String
    let primaryMotifs: [MotifEntry]
    let sacredVsDecorative: String
    let hiddenMeanings: [String]
    let crossCulturalOverlaps: [String]
    let mythologicalReferences: [String]
}

struct MotifEntry: Codable, Identifiable {
    let name: String
    let meaning: String
    let geometricDescription: String

    var id: String { name }
}

// MARK: - Cultural References

struct CulturalRefs: Codable {
    let summary: String
    let literaryReferences: [ReferenceEntry]
    let mythsAndFolklore: [ReferenceEntry]
    let artworks: [ReferenceEntry]
    let museumCollections: [String]
    let fashionReinterpretations: [String]
}

struct ReferenceEntry: Codable, Identifiable {
    let title: String
    let description: String
    let source: String

    var id: String { title }
}

// MARK: - Color Intelligence

struct ColorIntel: Codable {
    let summary: String
    let dominantColors: [ColorEntry]
    let emotionalAssociations: [String]
    let dyeHistory: String
    let statusMarkers: [String]
    let meaningEvolution: String
}

struct ColorEntry: Codable, Identifiable {
    let color: String
    var hexColor: String? = nil
    let symbolism: String
    let culturalMeaning: String
    var emotionalKeywords: [String]? = nil

    var id: String { color }
}

// MARK: - Material & Technique

struct MaterialTech: Codable {
    let summary: String
    let textileType: String
    let weavingTechnique: String
    let handcraftedVsIndustrial: String
    let regionSpecificTechniques: [String]
    let laborAndSocialHistory: String
    let sustainabilityNotes: String
    var didYouKnow: String? = nil
    var materialImageQuery: String? = nil
}

// MARK: - Music, Film & Pop Culture

struct PopCultureRefs: Codable {
    let summary: String
    let songs: [ReferenceEntry]
    let filmsAndCharacters: [ReferenceEntry]
    let subcultures: [String]
    let popHistoryMoments: [String]
    let notableArtists: [String]
}

// MARK: - Contemporary Relevance

struct ContemporaryRel: Codable {
    let summary: String
    let designerReinterpretations: [ReferenceEntry]
    let politicalSocialReclaiming: [String]
    let trendForecast: String
    let whyItResonatesNow: String
    let controversies: [String]
    var notableReferences: [CulturalMoment]? = nil
}

struct CulturalMoment: Codable, Identifiable {
    let category: String
    let description: String
    var imageQuery: String? = nil

    var id: String { "\(category)-\(description.prefix(20))" }
}

// MARK: - Cultural Shifts (Card 3)

struct CulturalShifts: Codable {
    let summary: String
    let revivalCycles: [String]
    let synthesis: String
}

// MARK: - Pattern Profile (Visual Meter)

struct PatternProfileAttribute: Codable, Identifiable {
    let name: String
    let score: Int

    var id: String { name }
}
