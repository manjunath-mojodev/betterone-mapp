import Foundation
import os.log

struct GeminiProvider: LLMProvider {
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models"
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "betterone", category: "GeminiProvider")

    private static let maxRetries = 3
    private static let retryDelays: [UInt64] = [2_000_000_000, 4_000_000_000, 8_000_000_000] // 2s, 4s, 8s
    private static let requestTimeoutSeconds: UInt64 = 30

    func sendMessage(messages: [LLMMessage], config: LLMConfiguration) async throws -> String {
        let request = try buildRequest(messages: messages, config: config, stream: false)
        Self.logger.info("➡️ \(request.httpMethod ?? "?") \(Self.redactedURL(request.url))")
        Self.logRequestBody(request)

        for attempt in 0..<Self.maxRetries {
            print("🔵 [Gemini] sendMessage attempt \(attempt + 1)/\(Self.maxRetries)")

            let (data, response) = try await Self.performRequest(request)

            print("🔵 [Gemini] got response: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
            Self.logResponse(response, data: data)

            if let http = response as? HTTPURLResponse, http.statusCode == 429 {
                Self.logger.warning("⏳ Rate limited (attempt \(attempt + 1)/\(Self.maxRetries)), retrying...")
                try await Task.sleep(nanoseconds: Self.retryDelays[attempt])
                continue
            }

            try validateResponse(response, data: data)

            let result = try JSONDecoder().decode(GeminiResponse.self, from: data)
            guard let text = result.candidates?.first?.content.parts.first?.text else {
                throw LLMError.invalidResponse
            }
            return text
        }

        throw LLMError.apiError(statusCode: 429, message: "Rate limited after \(Self.maxRetries) retries")
    }

    /// Runs the network request in a fully detached context (off MainActor) with a hard timeout.
    private static func performRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
        print("🔵 [Gemini] performRequest: starting detached network call")
        return try await withThrowingTaskGroup(of: (Data, URLResponse).self) { group in
            group.addTask {
                print("🔵 [Gemini] performRequest: URLSession.data starting")
                let result = try await URLSession.shared.data(for: request)
                print("🔵 [Gemini] performRequest: URLSession.data completed")
                return result
            }
            group.addTask {
                try await Task.sleep(nanoseconds: requestTimeoutSeconds * 1_000_000_000)
                print("🔴 [Gemini] performRequest: timeout after \(requestTimeoutSeconds)s")
                throw URLError(.timedOut)
            }
            guard let result = try await group.next() else {
                throw URLError(.timedOut)
            }
            group.cancelAll()
            return result
        }
    }

    func streamMessage(messages: [LLMMessage], config: LLMConfiguration) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task.detached { [self] in
                do {
                    let request = try self.buildRequest(messages: messages, config: config, stream: true)
                    Self.logger.info("➡️ STREAM \(request.httpMethod ?? "?") \(Self.redactedURL(request.url))")
                    Self.logRequestBody(request)

                    var lastResponse: URLResponse?
                    for attempt in 0..<Self.maxRetries {
                        let (bytes, response) = try await URLSession.shared.bytes(for: request)
                        lastResponse = response

                        if let http = response as? HTTPURLResponse, http.statusCode == 429 {
                            Self.logger.warning("⏳ Stream rate limited (attempt \(attempt + 1)/\(Self.maxRetries)), retrying...")
                            try await Task.sleep(nanoseconds: Self.retryDelays[attempt])
                            continue
                        }

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
                        return
                    }

                    // All retries exhausted
                    let code = (lastResponse as? HTTPURLResponse)?.statusCode ?? 429
                    continuation.finish(throwing: LLMError.apiError(statusCode: code, message: "Rate limited after \(Self.maxRetries) retries"))
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
        request.timeoutInterval = 60

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
