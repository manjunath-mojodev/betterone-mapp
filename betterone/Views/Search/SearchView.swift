import SwiftUI
import SwiftData

struct SearchView: View {
    @Environment(LLMService.self) private var llmService
    @Query(sort: \Topic.sortOrder) private var topics: [Topic]
    @State private var viewModel = SearchViewModel()
    @FocusState private var isSearchFocused: Bool

    private var displayResults: [TopicMatch] {
        viewModel.showLLMResults ? viewModel.llmResults : viewModel.localResults
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack(spacing: Theme.spacingSM) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(isSearchFocused ? Theme.accent : Theme.textSecondary)

                TextField("What would you like to explore?", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled()
                    .focused($isSearchFocused)
                    .submitLabel(.search)
                    .onSubmit {
                        viewModel.performSmartSearch(topics: topics, llmService: llmService)
                    }
                    .onChange(of: viewModel.searchText) {
                        viewModel.hasSubmitted = false
                        viewModel.llmResults = []
                        viewModel.performLocalSearch(topics: topics)
                    }

                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.clear()
                        isSearchFocused = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }
            .padding(Theme.spacingMD)
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerRadius)
                    .fill(Color(.systemBackground))
                    .shadow(color: Theme.accent.opacity(isSearchFocused ? 0.25 : 0.08), radius: isSearchFocused ? 8 : 4, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadius)
                    .stroke(isSearchFocused ? Theme.accent.opacity(0.5) : Theme.accent.opacity(0.15), lineWidth: 1.5)
            )
            .animation(.easeInOut(duration: 0.2), value: isSearchFocused)
            .padding(.horizontal, Theme.spacingLG)
            .padding(.top, Theme.spacingSM)

            // Results
            if viewModel.searchText.isEmpty {
                emptyState
            } else if viewModel.isSearchingLLM {
                loadingState
            } else if !displayResults.isEmpty {
                resultsList
            } else if viewModel.showNoResults {
                noResultsState
            } else if viewModel.localResults.isEmpty && !viewModel.hasSubmitted {
                submitHint
            }

            Spacer()
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .onTapGesture {
            isSearchFocused = false
        }
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - States

    private var emptyState: some View {
        VStack(spacing: Theme.spacingMD) {
            Image(systemName: "text.magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(Theme.textSecondary.opacity(0.5))
            Text("Search topics, concepts, or describe what you need help with")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 80)
        .padding(.horizontal, Theme.spacingXL)
    }

    private var loadingState: some View {
        VStack(spacing: Theme.spacingMD) {
            ProgressView()
            Text("Understanding your query...")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(.top, 60)
    }

    private var noResultsState: some View {
        VStack(spacing: Theme.spacingMD) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 36))
                .foregroundStyle(Theme.textSecondary.opacity(0.5))
            Text("No matching topics found")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(.top, 60)
    }

    private var submitHint: some View {
        Text("Press return to search with AI")
            .font(.caption)
            .foregroundStyle(Theme.textSecondary)
            .padding(.top, Theme.spacingLG)
    }

    private var resultsList: some View {
        ScrollView {
            LazyVStack(spacing: Theme.spacingSM) {
                if viewModel.showLLMResults {
                    Text("Suggested for you")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, Theme.spacingLG)
                        .padding(.top, Theme.spacingSM)
                }

                ForEach(displayResults) { match in
                    NavigationLink(value: match.topic) {
                        SearchResultRow(match: match)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, Theme.spacingSM)
            .padding(.bottom, 100)
        }
    }
}

// MARK: - Result Row

private struct SearchResultRow: View {
    let match: TopicMatch

    private var topicColor: Color {
        TopicCardView.colorForSlug(match.topic.slug)
    }

    var body: some View {
        HStack(spacing: Theme.spacingMD) {
            RoundedRectangle(cornerRadius: 3)
                .fill(topicColor)
                .frame(width: 6)

            Image(systemName: match.topic.iconName)
                .font(.title3)
                .foregroundStyle(topicColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: Theme.spacingXS) {
                Text(match.topic.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)

                Text(match.snippet ?? match.topic.subtitle)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary.opacity(0.5))
        }
        .padding(.vertical, Theme.spacingSM)
        .padding(.horizontal, Theme.spacingLG)
    }
}
