#if os(watchOS)
import SwiftUI

struct WatchConversationList: View {
    @State private var viewModel = ConversationListViewModel()
    @State private var selectedConversation: ConversationWithDetails?

    var body: some View {
        NavigationStack {
            if viewModel.isLoading && viewModel.conversations.isEmpty {
                ProgressView()
            } else if viewModel.conversations.isEmpty {
                VStack {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.title2)
                    Text("No chats")
                        .font(.caption)
                }
            } else {
                List(viewModel.conversations) { detail in
                    NavigationLink {
                        WatchChatView(
                            conversationId: detail.id,
                            title: detail.conversation.name ?? "Chat"
                        )
                    } label: {
                        WatchConversationRow(detail: detail)
                    }
                }
                .navigationTitle("Chats")
            }
        }
        .task {
            await viewModel.loadConversations()
        }
    }
}

struct WatchConversationRow: View {
    let detail: ConversationWithDetails

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(detail.conversation.name ?? "Chat")
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                if detail.unreadCount > 0 {
                    Text("\(detail.unreadCount)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(.blue)
                        .clipShape(Capsule())
                }
            }

            if let lastMessage = detail.lastMessage {
                Text(lastMessage.content)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 2)
    }
}
#endif
