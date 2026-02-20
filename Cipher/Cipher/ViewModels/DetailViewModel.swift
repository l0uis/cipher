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

    var culturalShifts: CulturalShifts?
    var patternProfile: [PatternProfileAttribute] = []

    var scanImage: UIImage?
    var materialImageURL: URL?
    var momentImageURLs: [String: URL] = [:]

    init(scan: PatternScan) {
        self.scan = scan
        decodeAllCategories()
    }

    func loadImage() async {
        scanImage = await ImageStorageService.shared.loadImage(fileName: scan.imageFileName)
    }

    func loadMaterialImage() async {
        let query = materialTech?.materialImageQuery
            ?? materialTech.map { "\($0.textileType) \($0.weavingTechnique) textile" }
        guard let query else { return }
        materialImageURL = await searchWikimediaImage(query: query)
    }

    func loadMomentImages() async {
        guard let refs = contemporary?.notableReferences else { return }
        await withTaskGroup(of: (String, URL?).self) { group in
            for ref in refs {
                guard let query = ref.imageQuery else { continue }
                let key = ref.id
                group.addTask {
                    let url = await self.searchWikimediaImage(query: query)
                    return (key, url)
                }
            }
            for await (key, url) in group {
                if let url { momentImageURLs[key] = url }
            }
        }
    }

    func refreshIfNeeded() {
        if scan.analysisStatus == "completed" && historyOrigins == nil {
            decodeAllCategories()
        }
    }

    private func searchWikimediaImage(query: String) async -> URL? {
        var components = URLComponents(string: "https://commons.wikimedia.org/w/api.php")!
        components.queryItems = [
            URLQueryItem(name: "action", value: "query"),
            URLQueryItem(name: "generator", value: "search"),
            URLQueryItem(name: "gsrsearch", value: query),
            URLQueryItem(name: "gsrnamespace", value: "6"),
            URLQueryItem(name: "prop", value: "imageinfo"),
            URLQueryItem(name: "iiprop", value: "url"),
            URLQueryItem(name: "iiurlwidth", value: "800"),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "gsrlimit", value: "1"),
        ]
        guard let url = components.url,
              let (data, _) = try? await URLSession.shared.data(from: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let queryResult = json["query"] as? [String: Any],
              let pages = queryResult["pages"] as? [String: Any],
              let firstPage = pages.values.first as? [String: Any],
              let imageinfo = firstPage["imageinfo"] as? [[String: Any]],
              let firstInfo = imageinfo.first,
              let thumburl = firstInfo["thumburl"] as? String else {
            return nil
        }
        return URL(string: thumburl)
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

        culturalShifts = decode(result.culturalShifts, as: CulturalShifts.self, decoder: decoder)
        if result.culturalShifts != nil && culturalShifts == nil {
            print("[Cipher] culturalShifts JSON present but decode failed: \(result.culturalShifts?.prefix(200) ?? "")")
        }
        patternProfile = decode(result.patternProfile, as: [PatternProfileAttribute].self, decoder: decoder) ?? []
        if result.patternProfile != nil && patternProfile.isEmpty {
            print("[Cipher] patternProfile JSON present but decode failed: \(result.patternProfile?.prefix(200) ?? "")")
        }
        print("[Cipher] Decoded — culturalShifts: \(culturalShifts != nil), patternProfile: \(patternProfile.count) items")

    }

    private func decode<T: Decodable>(_ jsonString: String?, as type: T.Type, decoder: JSONDecoder) -> T? {
        guard let string = jsonString, let data = string.data(using: .utf8) else { return nil }
        return try? decoder.decode(type, from: data)
    }
}
