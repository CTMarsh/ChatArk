import SwiftUI

private let shareOceanBlue = Color(red: 0.29, green: 0.545, blue: 0.761) // #4A8BC2

struct SharePickerView: View {
    let conversations: [ShareConversationSummary]
    let isStale: Bool
    let onCancel: () -> Void
    let onSend: (ShareConversationSummary) -> Void

    @State private var searchQuery = ""
    @State private var selectedConversation: ShareConversationSummary?
    @State private var isSending = false

    var body: some View {
        NavigationStack {
            Group {
                if conversations.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 0) {
                        if isStale {
                            staleBanner
                        }
                        conversationList
                    }
                }
            }
            .navigationTitle("Share to ChatArk")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSending {
                        ProgressView()
                    } else {
                        Button("Send") {
                            if let selected = selectedConversation {
                                isSending = true
                                onSend(selected)
                            }
                        }
                        .disabled(selectedConversation == nil)
                        .fontWeight(.semibold)
                    }
                }
            }
            .searchable(text: $searchQuery, prompt: "Search conversations")
        }
    }

    private var staleBanner: some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .font(.caption)
            Text("Conversation list may be outdated. Open ChatArk to refresh.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.1))
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "No Conversations",
            systemImage: "bubble.left.and.bubble.right",
            description: Text("Open ChatArk and start a conversation first.")
        )
    }

    private var conversationList: some View {
        List(filteredConversations) { conversation in
            Button {
                selectedConversation = conversation
            } label: {
                HStack(spacing: 12) {
                    initialsAvatar(for: conversation.name)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(conversation.name)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                        if !conversation.participantNames.isEmpty {
                            Text(conversation.participantNames.joined(separator: ", "))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    if selectedConversation?.id == conversation.id {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(shareOceanBlue)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private var filteredConversations: [ShareConversationSummary] {
        guard !searchQuery.isEmpty else { return conversations }
        let query = searchQuery.lowercased()
        return conversations.filter { conv in
            conv.name.lowercased().contains(query) ||
            conv.participantNames.contains { $0.lowercased().contains(query) }
        }
    }

    private func initialsAvatar(for name: String) -> some View {
        let initials = name.split(separator: " ")
            .prefix(2)
            .compactMap(\.first)
            .map(String.init)
            .joined()

        return Text(initials.isEmpty ? "?" : initials)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundStyle(.white)
            .frame(width: 36, height: 36)
            .background(shareOceanBlue.opacity(0.8))
            .clipShape(Circle())
    }
}

#if DEBUG
private let previewShareConversations = [
    ShareConversationSummary(id: "1", name: "Alice Johnson", avatarUrl: nil, participantNames: ["Alice"], type: "direct"),
    ShareConversationSummary(id: "2", name: "Team Chat", avatarUrl: nil, participantNames: ["Alice", "Bob", "Carol"], type: "group"),
    ShareConversationSummary(id: "3", name: "Bob Smith", avatarUrl: nil, participantNames: ["Bob"], type: "direct"),
]

#Preview("With conversations") {
    SharePickerView(conversations: previewShareConversations, isStale: false, onCancel: {}, onSend: { _ in })
}

#Preview("Stale") {
    SharePickerView(conversations: previewShareConversations, isStale: true, onCancel: {}, onSend: { _ in })
}

#Preview("Empty") {
    SharePickerView(conversations: [], isStale: false, onCancel: {}, onSend: { _ in })
}
#endif
