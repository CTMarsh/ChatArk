#if os(watchOS)
import SwiftUI

struct WatchChatView: View {
    let conversationId: UUID
    let title: String

    @State private var viewModel: ChatViewModel
    @State private var showQuickReply = false

    init(conversationId: UUID, title: String) {
        self.conversationId = conversationId
        self.title = title
        self._viewModel = State(initialValue: ChatViewModel(conversationId: conversationId))
    }

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isLoading {
                ProgressView()
            } else {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(Array(viewModel.messages.reversed().prefix(20)), id: \.id) { message in
                            WatchMessageRow(message: message)
                        }
                    }
                    .padding(.horizontal, 4)
                }

                // Quick reply button
                Button {
                    showQuickReply = true
                } label: {
                    HStack {
                        Image(systemName: "text.bubble")
                        Text("Reply")
                    }
                    .font(.caption)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle(title)
        .sheet(isPresented: $showQuickReply) {
            WatchQuickReply(conversationId: conversationId) { text in
                Task {
                    await viewModel.sendMessage(content: text)
                }
                showQuickReply = false
            }
        }
        .task {
            await viewModel.loadMessages()
            await viewModel.subscribe()
        }
        .onDisappear {
            Task { await viewModel.unsubscribe() }
        }
    }
}

struct WatchMessageRow: View {
    let message: Message
    private let currentUserId = SupabaseManager.shared.client.auth.currentUser?.id

    var body: some View {
        HStack {
            if message.senderId == currentUserId {
                Spacer()
            }

            VStack(alignment: message.senderId == currentUserId ? .trailing : .leading, spacing: 2) {
                if message.isDeleted {
                    Text("Deleted")
                        .font(.caption2)
                        .italic()
                        .foregroundStyle(.secondary)
                } else {
                    Text(message.content)
                        .font(.caption)
                        .lineLimit(5)
                }

                Text(DateFormatting.messageTime(message.createdAt))
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
            }
            .padding(6)
            .background(
                message.senderId == currentUserId
                    ? Color.blue.opacity(0.3)
                    : Color(.darkGray)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))

            if message.senderId != currentUserId {
                Spacer()
            }
        }
    }
}
#endif
