#if os(watchOS)
import SwiftUI
import NukeUI
import Supabase

struct WatchChatView: View {
    let conversationId: UUID
    let title: String

    @State private var viewModel: ChatViewModel
    @State private var showQuickReply = false

    private let currentUserId = SupabaseManager.shared.client.auth.currentUser?.id

    init(conversationId: UUID, title: String) {
        self.conversationId = conversationId
        self.title = title
        self._viewModel = State(initialValue: ChatViewModel(conversationId: conversationId))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            if viewModel.isLoading {
                ProgressView()
            } else if viewModel.messages.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "bubble.left")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    Text("No messages yet")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 6) {
                            if viewModel.hasMore {
                                Button("Load earlier") {
                                    Task { await viewModel.loadMore() }
                                }
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            }
                            ForEach(viewModel.messages.reversed(), id: \.id) { message in
                                WatchMessageRow(
                                    message: message,
                                    senderName: senderName(for: message),
                                    showSenderName: message.senderId != currentUserId
                                )
                                .id(message.id)
                            }

                            // Space for floating reply button
                            Color.clear.frame(height: 36)
                        }
                        .padding(.horizontal, 4)

                        typingIndicatorView
                    }
                    .defaultScrollAnchor(.bottom)
                    .onChange(of: viewModel.messages.count) {
                        HapticManager.messageReceived()
                        if let lastId = viewModel.messages.first?.id {
                            withAnimation {
                                proxy.scrollTo(lastId, anchor: .bottom)
                            }
                        }
                    }
                }
            }

            Button {
                showQuickReply = true
            } label: {
                Image(systemName: "arrowshape.turn.up.left.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(NauticalTheme.ocean)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .ignoresSafeArea(edges: .bottom)
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

    @ViewBuilder
    private var typingIndicatorView: some View {
        if !viewModel.typingUsers.isEmpty {
            let names = viewModel.typingUsers.compactMap { userId in
                viewModel.senderProfiles[userId]?.displayLabel ?? "Someone"
            }
            TypingIndicator(userNames: names)
                .frame(height: 20)
                .padding(.horizontal, 4)
        }
    }

    private func senderName(for message: Message) -> String {
        message.visitorName
            ?? viewModel.senderProfiles[message.senderId]?.displayLabel
            ?? "User"
    }
}

struct WatchMessageRow: View {
    let message: Message
    let senderName: String
    let showSenderName: Bool
    private let currentUserId = SupabaseManager.shared.client.auth.currentUser?.id

    private var isOwn: Bool {
        message.senderId == currentUserId
    }

    var body: some View {
        HStack {
            if isOwn { Spacer(minLength: 20) }

            VStack(alignment: isOwn ? .trailing : .leading, spacing: 2) {
                if showSenderName {
                    Text(senderName)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(NauticalTheme.ocean)
                }

                if message.isDeleted {
                    Text("Message deleted")
                        .font(.caption2)
                        .italic()
                        .foregroundStyle(.secondary)
                } else if let fileUrl = message.fileUrl, isImageAttachment(fileUrl) {
                    imageContent(fileUrl)
                    if !message.content.isEmpty {
                        Text(message.content)
                            .font(.caption2)
                            .lineLimit(3)
                    }
                } else {
                    Text(message.content)
                        .font(.caption2)
                        .lineLimit(8)
                }

                HStack(spacing: 4) {
                    if message.isEdited == true {
                        Text("edited")
                            .font(.system(size: 8))
                            .foregroundStyle(.tertiary)
                    }
                    Text(DateFormatting.messageTime(message.createdAt))
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(6)
            .background(isOwn ? NauticalTheme.ocean.opacity(0.3) : Color.gray.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            if !isOwn { Spacer(minLength: 20) }
        }
    }

    @ViewBuilder
    private func imageContent(_ fileUrl: String) -> some View {
        LazyImage(url: URL(string: fileUrl)) { state in
            if let image = state.image {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if state.isLoading {
                ProgressView()
                    .frame(width: 80, height: 60)
            } else {
                Image(systemName: "photo")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: 100, maxHeight: 80)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func isImageAttachment(_ url: String) -> Bool {
        let imageExtensions = ["jpg", "jpeg", "png", "gif", "webp", "heic"]
        let lowered = url.lowercased()
        return imageExtensions.contains { lowered.contains($0) }
    }
}

#if DEBUG
#Preview("Own message") {
    List {
        WatchMessageRow(message: PreviewData.ownTextMessage, senderName: "Chris", showSenderName: false)
    }
}

#Preview("Other's message") {
    List {
        WatchMessageRow(message: PreviewData.otherTextMessage, senderName: "Alice", showSenderName: true)
    }
}

#Preview("Deleted message") {
    List {
        WatchMessageRow(message: PreviewData.deletedMessage, senderName: "Bob", showSenderName: true)
    }
}
#endif
#endif
