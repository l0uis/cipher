import Foundation

actor EuropeanaService {
    static let shared = EuropeanaService()

    func searchRelatedRecords(query: String) async throws -> [EuropeanaItem] {
        var components = URLComponents(string: "\(AppConstants.API.serverBaseURL)/api/enrichment/europeana")!
        components.queryItems = [
            URLQueryItem(name: "q", value: query)
        ]

        let request = URLRequest(url: components.url!)
        let response: EuropeanaSearchResponse = try await NetworkClient.shared.performRequest(request)
        return response.items ?? []
    }
}
