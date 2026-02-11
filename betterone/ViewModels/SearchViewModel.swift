import Foundation
import SwiftData

struct TopicMatch: Identifiable {
    let id = UUID()
    let topic: Topic
    var snippet: String?
}

@Observable
final class SearchViewModel {
    var searchText: String = ""
    var localResults: [TopicMatch] = []
    var llmResults: [TopicMatch] = []
    var isSearchingLLM: Bool = false
    var hasSubmitted: Bool = false

    var showLLMResults: Bool {
        hasSubmitted && !llmResults.isEmpty
    }

    var showNoResults: Bool {
        hasSubmitted && localResults.isEmpty && llmResults.isEmpty && !isSearchingLLM
    }

    // MARK: - Local Search

    func performLocalSearch(topics: [Topic]) {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else {
            localResults = []
            return
        }

        var matches: [TopicMatch] = []

        for topic in topics where topic.isActive {
            // Check title and subtitle
            let titleHit = topic.title.localizedCaseInsensitiveContains(query)
            let subtitleHit = topic.subtitle.localizedCaseInsensitiveContains(query)

            // Check knowledge objects
            var bestSnippet: String?
            var knowledgeHits = 0

            for ko in topic.knowledgeObjects ?? [] {
                if ko.coreIdea.localizedCaseInsensitiveContains(query) {
                    bestSnippet = bestSnippet ?? ko.coreIdea
                    knowledgeHits += 1
                } else if ko.whenToUse.localizedCaseInsensitiveContains(query) {
                    bestSnippet = bestSnippet ?? ko.whenToUse
                    knowledgeHits += 1
                } else if ko.heuristics.contains(where: { $0.localizedCaseInsensitiveContains(query) }) {
                    bestSnippet = bestSnippet ?? ko.heuristics.first { $0.localizedCaseInsensitiveContains(query) }
                    knowledgeHits += 1
                }
            }

            if titleHit || subtitleHit || knowledgeHits > 0 {
                let snippet = bestSnippet ?? (subtitleHit ? topic.subtitle : nil)
                matches.append(TopicMatch(topic: topic, snippet: snippet))
            }
        }

        localResults = matches
    }

    // MARK: - LLM Smart Search

    func performSmartSearch(topics: [Topic], llmService: LLMService) {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }

        hasSubmitted = true

        isSearchingLLM = true
        llmResults = []

        let topicList = topics.filter(\.isActive).map { "\($0.slug): \($0.title) — \($0.subtitle)" }
            .joined(separator: "\n")

        let systemPrompt = """
            You are a topic matcher for a coaching app. Given a user query, return the slugs of the 1-3 most relevant topics from the list below, as a comma-separated list. Return ONLY the slugs, nothing else.

            Topics:
            \(topicList)
            """

        let userPrompt = query
        let allTopics = topics

        Task {
            do {
                let response = try await llmService.complete(messages: [
                    LLMMessage(role: "system", content: systemPrompt),
                    LLMMessage(role: "user", content: userPrompt)
                ])

                let slugs = response
                    .split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }

                let matched = slugs.compactMap { slug in
                    allTopics.first { $0.slug == slug }
                }.map { TopicMatch(topic: $0) }

                await MainActor.run {
                    self.llmResults = matched
                    self.isSearchingLLM = false
                }
            } catch {
                await MainActor.run {
                    self.isSearchingLLM = false
                }
            }
        }
    }

    func clear() {
        searchText = ""
        localResults = []
        llmResults = []
        hasSubmitted = false
        isSearchingLLM = false
    }
}
