import Foundation

/// Minimal Claude Messages API client used for the "Fix with AI" feature.
/// Requires Full Access (network) and an API key saved in the companion app.
enum ClaudeAPI {
    enum APIError: LocalizedError {
        case noAPIKey
        case badResponse(String)
        case emptyResult

        var errorDescription: String? {
            switch self {
            case .noAPIKey: return "No API key. Add one in the AIBoard app."
            case .badResponse(let message): return message
            case .emptyResult: return "The AI returned no text."
            }
        }
    }

    private static let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!
    private static let model = "claude-sonnet-5"

    /// Corrects grammar, punctuation, and spelling; preserves meaning and language.
    static func fixText(_ text: String, language: KeyboardLanguage) async throws -> String {
        guard let apiKey = KeychainHelper.loadAPIKey() else { throw APIError.noAPIKey }

        let system = """
        You are a grammar, spelling, and punctuation corrector. The text is in \(language.displayName). \
        Fix all grammatical mistakes, spelling errors, missing or wrong punctuation, and capitalization. \
        Keep the original meaning, tone, and language. Do not translate. \
        Return ONLY the corrected text with no commentary, no quotes, and no explanations.
        """

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 1024,
            "system": system,
            "messages": [["role": "user", "content": text]],
        ]

        var request = URLRequest(url: endpoint, timeoutInterval: 15)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw APIError.badResponse("No HTTP response.")
        }
        guard http.statusCode == 200 else {
            // Try to surface the API's error message.
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = json["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw APIError.badResponse(message)
            }
            throw APIError.badResponse("Request failed (HTTP \(http.statusCode)).")
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let first = content.first,
              let corrected = first["text"] as? String,
              !corrected.isEmpty else {
            throw APIError.emptyResult
        }
        return corrected.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Lightweight key check used by the companion app's "Test" button.
    static func testKey(_ key: String) async -> Bool {
        var request = URLRequest(url: endpoint, timeoutInterval: 15)
        request.httpMethod = "POST"
        request.setValue(key, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "model": model,
            "max_tokens": 8,
            "messages": [["role": "user", "content": "Say OK"]],
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        guard let (_, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse else { return false }
        return http.statusCode == 200
    }
}
