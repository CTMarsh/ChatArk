import SwiftUI

struct MessageSearchView: View {
    let conversationId: UUID?
    @State private var query = ""
    @State private var results: [Message] = []
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>?
    @Environment(\.dismiss) private var dismiss

    private let chatService = ChatService()

    var body: some View {
        NavigationStack {
            Group {
                if results.isEmpty && !isSearching && !query.isEmpty {
                    ContentUnavailableView.search(text: query)
                } else if results.isEmpty && query.isEmpty {
                    ContentUnavailableView(
                        "Search Messages",
                        systemImage: "magnifyingglass",
                        description: Text("Search across your conversation history")
                    )
                } else {
                    List(results) { message in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(message.content)
                                .lineLimit(3)
                            if let date = message.createdAt {
                                Text(date, style: .date)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Search")
            #if os(iOS) || os(visionOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .searchable(text: $query, prompt: "Search messages...")
            .onChange(of: query) {
                searchTask?.cancel()
                guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
                    results = []
                    return
                }
                searchTask = Task {
                    try? await Task.sleep(for: .milliseconds(300))
                    guard !Task.isCancelled else { return }
                    isSearching = true
                    defer { isSearching = false }
                    results = (try? await chatService.searchMessages(
                        query: query,
                        conversationId: conversationId
                    )) ?? []
                }
            }
            .overlay {
                if isSearching {
                    ProgressView()
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
