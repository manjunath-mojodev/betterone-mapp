import Foundation
import os.log

struct GeminiProvider: LLMProvider {
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models"
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "betterone", category: "GeminiProvider")

    func sendMessage(messages: [LLMMessage], config: LLMConfiguration) async throws -> String {
        let request = try buildRequest(messages: messages, config: config, stream: false)
        Self.logger.info("➡️ \(request.httpMethod ?? "?") \(Self.redactedURL(request.url))")
        Self.logRequestBody(request)

        let (data, response) = try await URLSession.shared.data(for: request)
        Self.logResponse(response, data: data)
        try validateResponse(response, data: data)

        let result = try JSONDecoder().decode(GeminiResponse.self, from: data)
        guard let text = result.candidates?.first?.content.parts.first?.text else {
            throw LLMError.invalidResponse
        }
        return text
    }

    func streamMessage(messages: [LLMMessage], config: LLMConfiguration) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let request = try buildRequest(messages: messages, config: config, stream: true)
                    Self.logger.info("➡️ STREAM \(request.httpMethod ?? "?") \(Self.redactedURL(request.url))")
                    Self.logRequestBody(request)

                    let (bytes, response) = try await URLSession.shared.bytes(for: request)
                    Self.logResponse(response, data: nil)
                    try validateResponse(response, data: nil)

                    for try await line in bytes.lines {
                        if Task.isCancelled { break }

                        guard line.hasPrefix("data: ") else { continue }
                        let payload = String(line.dropFirst(6))

                        guard let data = payload.data(using: .utf8),
                              let chunk = try? JSONDecoder().decode(GeminiResponse.self, from: data),
                              let text = chunk.candidates?.first?.content.parts.first?.text else { continue }

                        continuation.yield(text)
                    }
                    continuation.finish()
                } catch {
                    Self.logger.error("❌ Stream error: \(error.localizedDescription)")
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    // MARK: - Private

    private func buildRequest(messages: [LLMMessage], config: LLMConfiguration, stream: Bool) throws -> URLRequest {
        guard !config.apiKey.isEmpty else { throw LLMError.invalidAPIKey }

        let endpoint = stream ? "streamGenerateContent" : "generateContent"
        let sseParam = stream ? "&alt=sse" : ""
        let urlString = "\(baseURL)/\(config.model):\(endpoint)?key=\(config.apiKey)\(sseParam)"
        guard let url = URL(string: urlString) else { throw LLMError.invalidResponse }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Gemini: system instruction is separate, messages use "user"/"model" roles
        let systemMessage = messages.first(where: { $0.role == "system" })
        let conversationMessages = messages.filter { $0.role != "system" }

        var body: [String: Any] = [
            "contents": conversationMessages.map { msg -> [String: Any] in
                let role = msg.role == "assistant" ? "model" : "user"
                return ["role": role, "parts": [["text": msg.content]]]
            },
            "generationConfig": [
                "temperature": config.temperature,
                "maxOutputTokens": config.maxTokens
            ]
        ]

        if let systemContent = systemMessage?.content {
            body["systemInstruction"] = ["parts": [["text": systemContent]]]
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

    private static func redactedURL(_ url: URL?) -> String {
        guard let url else { return "<nil>" }
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url.absoluteString
        }
        let redacted = components.queryItems?.map { item in
            item.name == "key" ? URLQueryItem(name: "key", value: "***") : item
        }
        components.queryItems = redacted
        return components.string ?? url.absoluteString
    }

    private static func logRequestBody(_ request: URLRequest) {
        guard let body = request.httpBody,
              let json = String(data: body, encoding: .utf8) else { return }
        logger.debug("📤 Request body: \(json)")
    }

    private static func logResponse(_ response: URLResponse, data: Data?) {
        guard let http = response as? HTTPURLResponse else { return }
        let status = http.statusCode
        let bodyPreview = data.flatMap({ String(data: $0.prefix(2048), encoding: .utf8) }) ?? "<stream>"
        if (200...299).contains(status) {
            logger.info("✅ Response \(status)")
        } else {
            logger.error("❌ Response \(status): \(bodyPreview)")
        }
    }

    nonisolated private func validateResponse(_ response: URLResponse, data: Data?) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            let message = data.flatMap { String(data: $0, encoding: .utf8) } ?? "Unknown error"
            throw LLMError.apiError(statusCode: httpResponse.statusCode, message: message)
        }
    }
}

// MARK: - Response Types

private struct GeminiResponse: Codable {
    struct Candidate: Codable {
        struct Content: Codable {
            struct Part: Codable {
                let text: String?
            }
            let parts: [Part]
        }
        let content: Content
    }
    let candidates: [Candidate]?
}
