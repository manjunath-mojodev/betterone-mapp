import SwiftUI
import SwiftData

@Observable
final class HomeViewModel {
    var topics: [Topic] = []

    func loadTopics(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Topic>(sortBy: [SortDescriptor(\.sortOrder)])
        topics = (try? modelContext.fetch(descriptor)) ?? []
    }
}
