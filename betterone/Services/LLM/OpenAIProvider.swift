import Foundation

struct OpenAIProvider: LLMProvider {
    private let baseURL = "https://api.openai.com/v1/chat/completions"

    func sendMessage(messages: [LLMMessage], config: LLMConfiguration) async throws -> String {
        let request = try buildRequest(messages: messages, config: config, stream: false)
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response, data: data)

        let result = try JSONDecoder().decode(OpenAIChatResponse.self, from: data)
        guard let content = result.choices.first?.message.content else {
            throw LLMError.invalidResponse
        }
        return content
    }

    func streamMessage(messages: [LLMMessage], config: LLMConfiguration) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task.detached { [self] in
                do {
                    let request = try self.buildRequest(messages: messages, config: config, stream: true)
                    let (bytes, response) = try await URLSession.shared.bytes(for: request)
                    try self.validateResponse(response, data: nil)

                    for try await line in bytes.lines {
                        if Task.isCancelled { break }

                        guard line.hasPrefix("data: ") else { continue }
                        let payload = String(line.dropFirst(6))

                        if payload == "[DONE]" { break }

                        guard let data = payload.data(using: .utf8),
                              let chunk = try? JSONDecoder().decode(OpenAIStreamChunk.self, from: data),
                              let content = chunk.choices.first?.delta.content else { continue }

                        continuation.yield(content)
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
        guard let url = URL(string: baseURL) else { throw LLMError.invalidResponse }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": config.model,
            "messages": messages.map { ["role": $0.role, "content": $0.content] },
            "temperature": config.temperature,
            "max_tokens": config.maxTokens,
            "stream": stream
        ]
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

private struct OpenAIChatResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable {
            let content: String?
        }
        let message: Message
    }
    let choices: [Choice]
}

private struct OpenAIStreamChunk: Codable {
    struct Choice: Codable {
        struct Delta: Codable {
            let content: String?
        }
        let delta: Delta
    }
    let choices: [Choice]
}
