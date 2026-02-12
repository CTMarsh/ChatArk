import Foundation

@MainActor
@Observable
final class SearchViewModel {
    var query = ""
    var messageResults: [Message] = []
    var profileResults: [Profile] = []
    var isSearching = false
    var error: String?

    private let searchService: SearchService
    private var searchTask: Task<Void, Never>?
    // Rate limit: 5 searches burst, 1 per 2 seconds refill (full-text search is expensive)
    private let searchRateLimiter = RateLimiter(maxTokens: 5, refillInterval: 2.0)

    init(searchService: SearchService = SearchService()) {
        self.searchService = searchService
    }

    func search() {
        searchTask?.cancel()
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            messageResults = []
            profileResults = []
            return
        }

        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }

            guard searchRateLimiter.tryConsume() else {
                self.error = "Searching too fast. Please wait a moment."
                return
            }

            isSearching = true
            defer { isSearching = false }

            let truncatedQuery = String(query.prefix(200))

            do {
                async let messages = searchService.searchMessages(query: truncatedQuery)
                async let profiles = searchService.searchProfiles(query: truncatedQuery)

                messageResults = try await messages
                profileResults = try await profiles
            } catch {
                self.error = ErrorSanitizer.sanitize(error)
            }
        }
    }

    func searchInConversation(conversationId: UUID) {
        searchTask?.cancel()
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            messageResults = []
            return
        }

        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }

            guard searchRateLimiter.tryConsume() else {
                self.error = "Searching too fast. Please wait a moment."
                return
            }

            isSearching = true
            defer { isSearching = false }

            let truncatedQuery = String(query.prefix(200))

            do {
                messageResults = try await searchService.searchMessages(
                    query: truncatedQuery,
                    conversationId: conversationId
                )
            } catch {
                self.error = ErrorSanitizer.sanitize(error)
            }
        }
    }

    func clear() {
        query = ""
        messageResults = []
        profileResults = []
    }
}
