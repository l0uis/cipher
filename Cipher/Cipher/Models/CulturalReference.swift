import Foundation

// MARK: - Met Museum

struct MetMuseumSearchResponse: Codable {
    let total: Int
    let objectIDs: [Int]?
}

struct MetMuseumItem: Codable, Identifiable {
    let objectID: Int
    let title: String
    let artistDisplayName: String?
    let objectDate: String?
    let medium: String?
    let department: String?
    let culture: String?
    let primaryImageSmall: String?
    let objectURL: String?

    var id: Int { objectID }
}

// MARK: - Europeana

struct EuropeanaSearchResponse: Codable {
    let success: Bool
    let itemsCount: Int
    let totalResults: Int
    let items: [EuropeanaItem]?
}

struct EuropeanaItem: Codable, Identifiable {
    let id: String
    let title: [String]?
    let dcCreator: [String]?
    let dataProvider: [String]?
    let edmPreview: [String]?
    let guid: String?
    let year: [String]?
}
