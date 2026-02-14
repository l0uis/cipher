import SwiftUI

@Observable
class DetailViewModel {
    let scan: PatternScan

    var historyOrigins: HistoryOrigins?
    var symbolsMotifs: SymbolsMotifs?
    var culturalRefs: CulturalRefs?
    var colorIntel: ColorIntel?
    var materialTech: MaterialTech?
    var popCulture: PopCultureRefs?
    var contemporary: ContemporaryRel?

    var metItems: [MetMuseumItem] = []
    var europeanaItems: [EuropeanaItem] = []

    var scanImage: UIImage?

    init(scan: PatternScan) {
        self.scan = scan
        decodeAllCategories()
    }

    func loadImage() async {
        scanImage = await ImageStorageService.shared.loadImage(fileName: scan.imageFileName)
    }

    func refreshIfNeeded() {
        if scan.analysisStatus == "completed" && historyOrigins == nil {
            decodeAllCategories()
        }
    }

    private func decodeAllCategories() {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        guard let result = scan.analysisResult else { return }

        historyOrigins = decode(result.historyAndOrigins, as: HistoryOrigins.self, decoder: decoder)
        symbolsMotifs = decode(result.symbolsAndMotifs, as: SymbolsMotifs.self, decoder: decoder)
        culturalRefs = decode(result.culturalReferences, as: CulturalRefs.self, decoder: decoder)
        colorIntel = decode(result.colorIntelligence, as: ColorIntel.self, decoder: decoder)
        materialTech = decode(result.materialAndTechnique, as: MaterialTech.self, decoder: decoder)
        popCulture = decode(result.musicFilmPopCulture, as: PopCultureRefs.self, decoder: decoder)
        contemporary = decode(result.contemporaryRelevance, as: ContemporaryRel.self, decoder: decoder)

        metItems = decode(result.metMuseumResults, as: [MetMuseumItem].self, decoder: decoder) ?? []
        europeanaItems = decode(result.europeanaResults, as: [EuropeanaItem].self, decoder: decoder) ?? []
    }

    private func decode<T: Decodable>(_ jsonString: String?, as type: T.Type, decoder: JSONDecoder) -> T? {
        guard let string = jsonString, let data = string.data(using: .utf8) else { return nil }
        return try? decoder.decode(type, from: data)
    }
}
