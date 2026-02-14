import Foundation

actor ClaudeAPIService {
    static let shared = ClaudeAPIService()

    private let pollingInterval: UInt64 = 3_000_000_000 // 3 seconds
    private let maxPollingAttempts = 60 // 3 minutes max (60 * 3s)

    func analyzePattern(imageData: Data, mediaType: String = "image/jpeg") async throws -> PatternAnalysisResponse {
        let jobId = try await submitAnalysis(imageData: imageData)
        return try await pollForResult(jobId: jobId)
    }

    private func submitAnalysis(imageData: Data) async throws -> String {
        let base64Image = imageData.base64EncodedString()
        let body: [String: Any] = ["image": base64Image]

        var request = URLRequest(url: URL(string: "\(AppConstants.API.serverBaseURL)/api/analyze")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 120

        let response: AnalysisJobResponse = try await NetworkClient.shared.performRequest(request)
        return response.jobId
    }

    private func pollForResult(jobId: String) async throws -> PatternAnalysisResponse {
        for _ in 0..<maxPollingAttempts {
            try await Task.sleep(nanoseconds: pollingInterval)

            var request = URLRequest(url: URL(string: "\(AppConstants.API.serverBaseURL)/api/analyze/\(jobId)")!)
            request.httpMethod = "GET"
            request.timeoutInterval = 15

            let status: JobStatusResponse = try await NetworkClient.shared.performRequest(request)

            switch status.status {
            case "completed":
                guard let result = status.result else {
                    throw AnalysisError.missingResult
                }
                return result
            case "failed":
                throw AnalysisError.serverError(status.error ?? "Unknown error")
            default:
                continue
            }
        }

        throw AnalysisError.timeout
    }
}

private struct AnalysisJobResponse: Codable {
    let jobId: String
}

private struct JobStatusResponse: Codable {
    let status: String
    let result: PatternAnalysisResponse?
    let error: String?
}

enum AnalysisError: LocalizedError {
    case missingResult
    case serverError(String)
    case timeout

    var errorDescription: String? {
        switch self {
        case .missingResult:
            return "Server returned completed but no result data"
        case .serverError(let message):
            return "Analysis failed: \(message)"
        case .timeout:
            return "Analysis timed out. Please try again."
        }
    }
}
