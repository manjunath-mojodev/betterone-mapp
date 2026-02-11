import Foundation
import os.log

struct GeminiProvider: LLMProvider {
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models"
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "betterone", category: "GeminiProvider")

    func sendMessage(messages: [LLMMessage], config: LLMConfiguration) async throws -> String {
        let request = try buildRequest(messages: messages, config: config, stream: false)
        Self.logger.info("➡️ \(request.httpMethod ?? "?") \(Self.redactedURL(request.url))")
        Self.logRequestBody(request)

        print("🔵 [Gemini] sendMessage: starting request")
        let (data, response) = try await URLSession.shared.data(for: request)

        print("🔵 [Gemini] got response: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
        Self.logResponse(response, data: data)

        try validateResponse(response, data: data)

        let result = try JSONDecoder().decode(GeminiResponse.self, from: data)
        guard let text = result.candidates?.first?.content.parts.first?.text else {
            throw LLMError.invalidResponse
        }
        return text
    }

    /// Callback-based send — zero Swift concurrency, zero Tasks, pure URLSession.
    @discardableResult
    func send(messages: [LLMMessage], config: LLMConfiguration,
              completion: @escaping @Sendable (Result<String, Error>) -> Void) -> URLSessionTask? {
        let request: URLRequest
        do {
            request = try buildRequest(messages: messages, config: config, stream: false)
        } catch {
            completion(.failure(error))
            return nil
        }

        Self.logger.info("➡️ CB \(request.httpMethod ?? "?") \(Self.redactedURL(request.url))")
        print("🔵 [Gemini] callback send: starting dataTask")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error {
                print("🔴 [Gemini] callback send: network error")
                completion(.failure(LLMError.networkError(error)))
                return
            }
            guard let data, let response else {
                completion(.failure(LLMError.invalidResponse))
                return
            }

            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            print("🔵 [Gemini] callback send: got \(statusCode)")

            // Validate
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                let msg: String
                if statusCode == 429 {
                    msg = "Rate limited — please wait a moment and try again."
                } else {
                    msg = String((String(data: data, encoding: .utf8) ?? "Unknown error").prefix(200))
                }
                completion(.failure(LLMError.apiError(statusCode: statusCode, message: msg)))
                return
            }

            // Decode
            do {
                let result = try JSONDecoder().decode(GeminiResponse.self, from: data)
                guard let text = result.candidates?.first?.content.parts.first?.text else {
                    completion(.failure(LLMError.invalidResponse))
                    return
                }
                completion(.success(text))
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
        return task
    }

    func streamMessage(messages: [LLMMessage], config: LLMConfiguration) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task.detached { [self] in
                do {
                    let request = try self.buildRequest(messages: messages, config: config, stream: true)
                    Self.logger.info("➡️ STREAM \(request.httpMethod ?? "?") \(Self.redactedURL(request.url))")
                    Self.logRequestBody(request)

                    let (bytes, response) = try await URLSession.shared.bytes(for: request)
                    Self.logResponse(response, data: nil)
                    try self.validateResponse(response, data: nil)

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
        request.timeoutInterval = 30

        // Gemini: system instruction is separate, messages use "user"/"model" roles
        let systemMessage = messages.first(where: { $0.role == "system" })
        var conversationMessages = messages.filter { $0.role != "system" }
        var systemContent = systemMessage?.content ?? ""

        // Gemini requires first content to have "user" role.
        // Merge any leading assistant messages into the system instruction.
        while let first = conversationMessages.first, first.role == "assistant" {
            systemContent += "\n\n[Your previous message: \(first.content)]"
            conversationMessages.removeFirst()
        }

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

        if !systemContent.isEmpty {
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
            let raw = data.flatMap { String(data: $0, encoding: .utf8) } ?? "Unknown error"
            // Extract a short error message for the UI
            let message: String
            if httpResponse.statusCode == 429 {
                message = "Rate limited — please wait a moment and try again."
            } else {
                message = String(raw.prefix(200))
            }
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
