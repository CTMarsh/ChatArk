import SwiftUI
import PhotosUI
import Supabase

struct ChatView: View {
    let conversationId: UUID
    let title: String

    @State private var viewModel: ChatViewModel
    @State private var messageText = ""
    @State private var showEmojiPicker = false
    @State private var showFilePicker = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showImageViewer: URL?
    @State private var typingDebounce: Task<Void, Never>?
    @FocusState private var isComposeFocused: Bool

    init(conversationId: UUID, title: String) {
        self.conversationId = conversationId
        self.title = title
        self._viewModel = State(initialValue: ChatViewModel(conversationId: conversationId))
    }

    var body: some View {
        VStack(spacing: 0) {
            pinnedBanner
            messagesList
            TypingIndicator(userNames: viewModel.typingUsers.map { _ in "User" })
            composeBar
        }
        .navigationTitle(title)
        #if os(iOS) || os(visionOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .sheet(isPresented: $showEmojiPicker) {
            EmojiPicker { emoji in
                messageText += emoji
            }
            .presentationDetents([.medium])
        }
        .sheet(item: $showImageViewer) { url in
            ImageViewer(url: url)
        }
        .task {
            await viewModel.loadMessages()
            await viewModel.subscribe()
        }
        .onDisappear {
            Task { await viewModel.unsubscribe() }
        }
    }

    // MARK: - Pinned Banner

    @ViewBuilder
    private var pinnedBanner: some View {
        if !viewModel.pinnedMessages.isEmpty {
            PinnedMessageBanner(messages: viewModel.pinnedMessages) { _ in }
        }
    }

    // MARK: - Messages List

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 8) {
                    loadMoreButton
                    ForEach(Array(viewModel.messages.reversed()), id: \.id) { message in
                        messageRow(for: message)
                            .id(message.id)
                    }
                }
                .padding(.vertical, 8)
            }
            .onChange(of: viewModel.messages.count) {
                if let lastId = viewModel.messages.first?.id {
                    withAnimation {
                        proxy.scrollTo(lastId, anchor: .bottom)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var loadMoreButton: some View {
        if viewModel.hasMore {
            Button("Load more") {
                Task { await viewModel.loadMore() }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding()
        }
    }

    private func messageRow(for message: Message) -> some View {
        let isOwn = message.senderId == SupabaseManager.shared.client.auth.currentUser?.id
        let reactions = viewModel.reactions[message.id] ?? []
        let profile = viewModel.senderProfiles[message.senderId]
        let senderName = message.visitorName ?? profile?.displayLabel ?? "User"
        let senderAvatarUrl = profile?.avatarUrl
        return MessageRow(
            message: message,
            isFromCurrentUser: isOwn,
            senderName: senderName,
            senderAvatarUrl: senderAvatarUrl,
            reactions: reactions,
            onReaction: { emoji in
                Task { await viewModel.addReaction(messageId: message.id, emoji: emoji) }
            },
            onReply: {
                viewModel.replyingTo = message
                isComposeFocused = true
            },
            onEdit: {
                viewModel.editingMessage = message
                messageText = message.content
                isComposeFocused = true
            },
            onDelete: {
                Task { await viewModel.deleteMessage(messageId: message.id) }
            },
            onPin: {
                Task {
                    if message.isPinned == true {
                        await viewModel.unpinMessage(messageId: message.id)
                    } else {
                        await viewModel.pinMessage(messageId: message.id)
                    }
                }
            }
        )
    }

    // MARK: - Compose Bar

    private var composeBar: some View {
        VStack(spacing: 0) {
            replyPreview
            editPreview
            Divider()
            composeRow
        }
        .background(.bar)
    }

    @ViewBuilder
    private var replyPreview: some View {
        if let reply = viewModel.replyingTo {
            HStack {
                Rectangle()
                    .fill(.blue)
                    .frame(width: 3)
                VStack(alignment: .leading) {
                    Text("Reply")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Text(reply.content)
                        .font(.caption)
                        .lineLimit(1)
                }
                Spacer()
                Button { viewModel.replyingTo = nil } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
            .background(Color.gray.opacity(0.12))
        }
    }

    @ViewBuilder
    private var editPreview: some View {
        if viewModel.editingMessage != nil {
            HStack {
                Image(systemName: "pencil")
                    .foregroundStyle(.blue)
                Text("Editing message")
                    .font(.caption)
                Spacer()
                Button {
                    viewModel.editingMessage = nil
                    messageText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
            .background(Color.gray.opacity(0.12))
        }
    }

    private var composeRow: some View {
        HStack(alignment: .bottom, spacing: 10) {
            attachmentMenu
            photoPicker
            emojiButton
            textField
            sendButton
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var attachmentMenu: some View {
        Menu {
            Button {
                showFilePicker = true
            } label: {
                Label("File", systemImage: "doc")
            }
        } label: {
            Image(systemName: "plus.circle.fill")
                .font(.title)
                .frame(width: 36, height: 36)
                .foregroundStyle(.blue)
        }
    }

    private var photoPicker: some View {
        PhotosPicker(selection: $selectedPhoto, matching: .images) {
            Image(systemName: "photo")
                .font(.title2)
                .frame(width: 36, height: 36)
                .foregroundStyle(.blue)
        }
        .onChange(of: selectedPhoto) { _, newValue in
            guard let item = newValue else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    let storageService = StorageService()
                    if let url = try? await storageService.uploadMessageAttachment(
                        data: data,
                        fileName: "photo.jpg",
                        contentType: "image/jpeg",
                        conversationId: conversationId
                    ) {
                        await viewModel.sendMessage(
                            content: "Sent a photo",
                            type: .image,
                            fileUrl: url,
                            fileName: "photo.jpg",
                            fileSize: Int64(data.count),
                            fileType: "image/jpeg"
                        )
                    }
                }
                selectedPhoto = nil
            }
        }
    }

    private var emojiButton: some View {
        Button {
            showEmojiPicker = true
        } label: {
            Image(systemName: "face.smiling")
                .font(.title2)
                .frame(width: 36, height: 36)
                .foregroundStyle(.blue)
        }
    }

    private var textField: some View {
        TextField("Message...", text: $messageText, axis: .vertical)
            .textFieldStyle(.plain)
            .lineLimit(1...8)
            .padding(.horizontal, 12)
            .frame(minHeight: 36)
            .background(Color.gray.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .focused($isComposeFocused)
            .onSubmit {
                sendMessage()
            }
            .onChange(of: messageText) {
                typingDebounce?.cancel()
                Task { await viewModel.sendTypingIndicator(isTyping: true) }
                typingDebounce = Task {
                    try? await Task.sleep(for: .seconds(3))
                    await viewModel.sendTypingIndicator(isTyping: false)
                }
            }
    }

    private var sendButton: some View {
        Button {
            sendMessage()
        } label: {
            Image(systemName: "arrow.up.circle.fill")
                .font(.title)
                .frame(width: 36, height: 36)
                .foregroundStyle(messageText.trimmingCharacters(in: .whitespaces).isEmpty ? .gray : .blue)
        }
        .disabled(messageText.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isSending)
    }

    // MARK: - Actions

    private func sendMessage() {
        let content = messageText.trimmingCharacters(in: .whitespaces)
        guard !content.isEmpty else { return }

        if let editing = viewModel.editingMessage {
            Task {
                await viewModel.editMessage(messageId: editing.id, newContent: content)
                messageText = ""
            }
        } else {
            Task {
                await viewModel.sendMessage(content: content)
                messageText = ""
            }
        }

        HapticManager.messageSent()
        Task { await viewModel.sendTypingIndicator(isTyping: false) }
    }
}

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}
