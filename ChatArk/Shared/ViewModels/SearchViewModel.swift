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

            isSearching = true
            defer { isSearching = false }

            do {
                async let messages = searchService.searchMessages(query: query)
                async let profiles = searchService.searchProfiles(query: query)

                messageResults = try await messages
                profileResults = try await profiles
            } catch {
                self.error = error.localizedDescription
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

            isSearching = true
            defer { isSearching = false }

            do {
                messageResults = try await searchService.searchMessages(
                    query: query,
                    conversationId: conversationId
                )
            } catch {
                self.error = error.localizedDescription
            }
        }
    }

    func clear() {
        query = ""
        messageResults = []
        profileResults = []
    }
}
