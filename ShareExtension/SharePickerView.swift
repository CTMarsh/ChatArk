import SwiftUI

struct SharePickerView: View {
    let conversations: [ShareConversationSummary]
    let onCancel: () -> Void
    let onSend: (ShareConversationSummary) -> Void

    @State private var searchQuery = ""
    @State private var selectedConversation: ShareConversationSummary?

    var body: some View {
        NavigationStack {
            Group {
                if conversations.isEmpty {
                    emptyState
                } else {
                    conversationList
                }
            }
            .navigationTitle("Share to ChatArk")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Send") {
                        if let selected = selectedConversation {
                            onSend(selected)
                        }
                    }
                    .disabled(selectedConversation == nil)
                    .fontWeight(.semibold)
                }
            }
            .searchable(text: $searchQuery, prompt: "Search conversations")
        }
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
                            .foregroundStyle(.blue)
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
            .background(.blue.opacity(0.8))
            .clipShape(Circle())
    }
}
