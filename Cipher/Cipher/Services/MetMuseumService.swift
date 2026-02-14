import Foundation

actor MetMuseumService {
    static let shared = MetMuseumService()

    func searchRelatedArtworks(query: String, medium: String? = nil) async throws -> [MetMuseumItem] {
        var components = URLComponents(string: "\(AppConstants.API.metMuseumBaseURL)/search")!
        var queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "hasImages", value: "true")
        ]
        if let medium {
            queryItems.append(URLQueryItem(name: "medium", value: medium))
        }
        components.queryItems = queryItems

        let request = URLRequest(url: components.url!)
        let searchResult: MetMuseumSearchResponse = try await NetworkClient.shared.performRequest(request)

        guard let objectIDs = searchResult.objectIDs else { return [] }

        let limitedIDs = Array(objectIDs.prefix(AppConstants.UI.maxEnrichmentResults))

        return await withTaskGroup(of: MetMuseumItem?.self) { group in
            for objectID in limitedIDs {
                group.addTask {
                    try? await self.fetchObject(id: objectID)
                }
            }
            var items: [MetMuseumItem] = []
            for await item in group {
                if let item { items.append(item) }
            }
            return items
        }
    }

    private func fetchObject(id: Int) async throws -> MetMuseumItem {
        let url = URL(string: "\(AppConstants.API.metMuseumBaseURL)/objects/\(id)")!
        return try await NetworkClient.shared.performRequest(URLRequest(url: url))
    }
}
