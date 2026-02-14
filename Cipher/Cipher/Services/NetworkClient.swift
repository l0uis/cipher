import Foundation
import Network

actor NetworkClient {
    static let shared = NetworkClient()

    private let session: URLSession
    private let decoder: JSONDecoder

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 300
        config.timeoutIntervalForResource = 300
        config.connectionProxyDictionary = [:]
        if #available(iOS 17.0, *) {
            config.proxyConfigurations = []  // Bypass iCloud Private Relay
        }
        self.session = URLSession(configuration: config)
        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
    }

    func performRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "No body"
            throw NetworkError.httpError(statusCode: httpResponse.statusCode, body: body)
        }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingError(error)
        }
    }

    func performRequestRawData(_ request: URLRequest) async throws -> Data {
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            let body = String(data: data, encoding: .utf8) ?? "No body"
            throw NetworkError.httpError(statusCode: statusCode, body: body)
        }
        return data
    }
}

enum NetworkError: LocalizedError {
    case invalidResponse
    case httpError(statusCode: Int, body: String)
    case decodingError(Error)
    case missingAPIKey

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid server response"
        case .httpError(let code, let body):
            return "HTTP \(code): \(body.prefix(200))"
        case .decodingError(let err):
            return "Decoding error: \(err.localizedDescription)"
        case .missingAPIKey:
            return "API key not configured. Please add your API key in Settings."
        }
    }
}
