import Foundation

struct ClaudeProvider: LLMProvider {
    private let baseURL = "https://api.anthropic.com/v1/messages"

    func sendMessage(messages: [LLMMessage], config: LLMConfiguration) async throws -> String {
        let request = try buildRequest(messages: messages, config: config, stream: false)
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response, data: data)

        let result = try JSONDecoder().decode(ClaudeResponse.self, from: data)
        guard let textBlock = result.content.first(where: { $0.type == "text" }) else {
            throw LLMError.invalidResponse
        }
        return textBlock.text ?? ""
    }

    func streamMessage(messages: [LLMMessage], config: LLMConfiguration) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let request = try buildRequest(messages: messages, config: config, stream: true)
                    let (bytes, response) = try await URLSession.shared.bytes(for: request)
                    try validateResponse(response, data: nil)

                    for try await line in bytes.lines {
                        if Task.isCancelled { break }

                        guard line.hasPrefix("data: ") else { continue }
                        let payload = String(line.dropFirst(6))

                        guard let data = payload.data(using: .utf8) else { continue }

                        if let delta = try? JSONDecoder().decode(ClaudeStreamDelta.self, from: data),
                           delta.type == "content_block_delta",
                           let text = delta.delta?.text {
                            continuation.yield(text)
                        }

                        if let event = try? JSONDecoder().decode(ClaudeStreamEvent.self, from: data),
                           event.type == "message_stop" {
                            break
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    // MARK: - Private

    private func buildRequest(messages: [LLMMessage], config: LLMConfiguration, stream: Bool) throws -> URLRequest {
        guard !config.apiKey.isEmpty else { throw LLMError.invalidAPIKey }

        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue(config.apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Claude API: system prompt is top-level, not in messages array
        let systemMessage = messages.first(where: { $0.role == "system" })
        let conversationMessages = messages.filter { $0.role != "system" }

        var body: [String: Any] = [
            "model": config.model,
            "messages": conversationMessages.map { ["role": $0.role, "content": $0.content] },
            "temperature": config.temperature,
            "max_tokens": config.maxTokens,
            "stream": stream
        ]

        if let systemContent = systemMessage?.content {
            body["system"] = systemContent
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
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

private struct ClaudeResponse: Codable {
    struct ContentBlock: Codable {
        let type: String
        let text: String?
    }
    let content: [ContentBlock]
}

private struct ClaudeStreamDelta: Codable {
    struct Delta: Codable {
        let type: String?
        let text: String?
    }
    let type: String
    let delta: Delta?
}

private struct ClaudeStreamEvent: Codable {
    let type: String
}
