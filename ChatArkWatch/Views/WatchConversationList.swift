#if os(watchOS)
import SwiftUI
import Supabase

struct WatchConversationList: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var viewModel = ConversationListViewModel()

    private var currentUserId: UUID? {
        authViewModel.currentUser?.id
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.conversations.isEmpty {
                ProgressView()
            } else if viewModel.conversations.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("No Conversations")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Text("Start a chat on your iPhone")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } else {
                List(viewModel.conversations) { detail in
                    NavigationLink {
                        WatchChatView(
                            conversationId: detail.id,
                            title: displayName(for: detail)
                        )
                    } label: {
                        WatchConversationRow(
                            detail: detail,
                            currentUserId: currentUserId
                        )
                    }
                }
            }
        }
        .navigationTitle("Chats")
        .refreshable {
            await viewModel.loadConversations()
        }
        .task {
            await viewModel.loadConversations()
            await viewModel.subscribe()
        }
    }

    private func displayName(for detail: ConversationWithDetails) -> String {
        if let name = detail.conversation.name {
            return name
        }
        if let other = detail.participants.first(where: { $0.id != currentUserId }) {
            return other.displayLabel
        }
        return "Conversation"
    }
}

struct WatchConversationRow: View {
    let detail: ConversationWithDetails
    let currentUserId: UUID?

    var body: some View {
        HStack(spacing: 10) {
            ZStack(alignment: .bottomTrailing) {
                AvatarView(
                    url: detail.conversation.avatarUrl ?? otherParticipant?.avatarUrl,
                    name: displayName,
                    size: 36
                )
                if let status = otherParticipant?.status, detail.conversation.type == .direct {
                    StatusIndicator(status: status, size: 10)
                        .offset(x: 2, y: 2)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(displayName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .lineLimit(1)

                    Spacer()

                    if detail.unreadCount > 0 {
                        Text("\(detail.unreadCount)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(NauticalTheme.ocean)
                            .clipShape(Capsule())
                    }
                }

                HStack {
                    if let lastMessage = detail.lastMessage {
                        if lastMessage.isDeleted {
                            Text("Message deleted")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .italic()
                        } else {
                            Text(lastMessage.content)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    } else {
                        Text("No messages yet")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }

                    Spacer()

                    Text(DateFormatting.conversationDate(detail.lastMessage?.createdAt ?? detail.conversation.updatedAt))
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private var displayName: String {
        if let name = detail.conversation.name {
            return name
        }
        if let other = otherParticipant {
            return other.displayLabel
        }
        return "Conversation"
    }

    private var otherParticipant: Profile? {
        detail.participants.first { $0.id != currentUserId }
    }
}

#if DEBUG
#Preview("DM row") {
    List {
        WatchConversationRow(detail: PreviewData.dmDetail, currentUserId: PreviewData.currentUserId)
    }
}

#Preview("Group row") {
    List {
        WatchConversationRow(detail: PreviewData.groupDetail, currentUserId: PreviewData.currentUserId)
    }
}

#Preview("Unread row") {
    List {
        WatchConversationRow(detail: PreviewData.dmDetail, currentUserId: PreviewData.currentUserId)
    }
}
#endif
#endif
