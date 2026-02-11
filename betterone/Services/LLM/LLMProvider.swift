import Foundation

struct LLMMessage: Codable, Sendable {
    let role: String
    let content: String
}

enum LLMError: LocalizedError {
    case invalidAPIKey
    case invalidResponse
    case apiError(statusCode: Int, message: String)
    case networkError(Error)
    case streamingError(String)

    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "API key is missing or invalid."
        case .invalidResponse:
            return "Received an invalid response from the API."
        case .apiError(let code, let message):
            return "API error (\(code)): \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .streamingError(let message):
            return "Streaming error: \(message)"
        }
    }
}

protocol LLMProvider: Sendable {
    func sendMessage(messages: [LLMMessage], config: LLMConfiguration) async throws -> String
    func streamMessage(messages: [LLMMessage], config: LLMConfiguration) -> AsyncThrowingStream<String, Error>

    /// Callback-based send that bypasses Swift concurrency entirely.
    /// Returns a cancellable URLSessionTask.
    @discardableResult
    func send(messages: [LLMMessage], config: LLMConfiguration,
              completion: @escaping @Sendable (Result<String, Error>) -> Void) -> URLSessionTask?
}

extension LLMProvider {
    // Default: bridges to the async version via Task.detached
    func send(messages: [LLMMessage], config: LLMConfiguration,
              completion: @escaping @Sendable (Result<String, Error>) -> Void) -> URLSessionTask? {
        Task.detached {
            do {
                let result = try await self.sendMessage(messages: messages, config: config)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }
        return nil
    }
}
