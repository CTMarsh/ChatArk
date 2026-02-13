import SwiftUI
import PhotosUI
import Supabase
import UniformTypeIdentifiers

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
            ChatMessagesListView(viewModel: viewModel, showImageViewer: $showImageViewer, isComposeFocused: $isComposeFocused, messageText: $messageText)
            ChatTypingView(viewModel: viewModel)
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
        .fileImporter(isPresented: $showFilePicker, allowedContentTypes: [.item]) { result in
            guard case .success(let url) = result else { return }
            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }
            Task {
                guard let data = try? Data(contentsOf: url) else { return }
                let maxSize = 50 * 1024 * 1024 // 50MB
                guard data.count <= maxSize else {
                    viewModel.chatError = .fileTooLarge(maxMB: 50)
                    return
                }
                let fileName = url.lastPathComponent
                let contentType = UTType(filenameExtension: url.pathExtension)?.preferredMIMEType ?? "application/octet-stream"
                let storageService = StorageService()
                do {
                    let uploadedUrl = try await storageService.uploadMessageAttachment(
                        data: data,
                        fileName: fileName,
                        contentType: contentType,
                        conversationId: conversationId
                    )
                    await viewModel.sendMessage(
                        content: "Sent a file: \(fileName)",
                        type: .file,
                        fileUrl: uploadedUrl,
                        fileName: fileName,
                        fileSize: Int64(data.count),
                        fileType: contentType
                    )
                } catch {
                    viewModel.chatError = .uploadFailed(error.localizedDescription)
                }
            }
        }
        #if os(macOS)
        .dropDestination(for: URL.self) { urls, _ in
            guard let url = urls.first else { return false }
            let capturedConversationId = conversationId
            let capturedViewModel = viewModel
            Task { @MainActor in
                guard let data = try? Data(contentsOf: url) else { return }
                let fileName = url.lastPathComponent
                let contentType = UTType(filenameExtension: url.pathExtension)?.preferredMIMEType ?? "application/octet-stream"
                let storageService = StorageService()
                if let uploadedUrl = try? await storageService.uploadMessageAttachment(
                    data: data,
                    fileName: fileName,
                    contentType: contentType,
                    conversationId: capturedConversationId
                ) {
                    await capturedViewModel.sendMessage(
                        content: "Sent a file: \(fileName)",
                        type: .file,
                        fileUrl: uploadedUrl,
                        fileName: fileName,
                        fileSize: Int64(data.count),
                        fileType: contentType
                    )
                }
            }
            return true
        }
        #endif
        .alert(
            "Error",
            isPresented: Binding(
                get: { viewModel.chatError != nil },
                set: { if !$0 { viewModel.chatError = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
            if case .sessionExpired = viewModel.chatError {
                Button("Sign In") {
                    viewModel.chatError = nil
                }
            }
        } message: {
            if let chatError = viewModel.chatError {
                Text(chatError.localizedDescription)
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

    // MARK: - Pinned Banner

    @ViewBuilder
    private var pinnedBanner: some View {
        if !viewModel.pinnedMessages.isEmpty {
            PinnedMessageBanner(messages: viewModel.pinnedMessages) { _ in }
        }
    }

    // MARK: - Compose Bar

    private var composeBar: some View {
        VStack(spacing: 0) {
            replyPreview
            editPreview
            Divider()
            if messageText.count > ChatViewModel.maxMessageLength - 500 {
                charCountBar
            }
            composeRow
        }
        .background(.bar)
    }

    private var charCountBar: some View {
        let remaining = ChatViewModel.maxMessageLength - messageText.count
        return HStack {
            Spacer()
            Text("\(remaining)")
                .font(.caption2)
                .monospacedDigit()
                .foregroundStyle(remaining < 0 ? .red : remaining < 200 ? .orange : .secondary)
        }
        .padding(.horizontal, 14)
        .padding(.top, 4)
    }

    @ViewBuilder
    private var replyPreview: some View {
        if let reply = viewModel.replyingTo {
            HStack {
                Rectangle()
                    .fill(NauticalTheme.ocean)
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
                    .foregroundStyle(NauticalTheme.ocean)
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
                .foregroundStyle(NauticalTheme.ocean)
        }
    }

    private var photoPicker: some View {
        PhotosPicker(selection: $selectedPhoto, matching: .images) {
            Image(systemName: "photo")
                .font(.title2)
                .frame(width: 36, height: 36)
                .foregroundStyle(NauticalTheme.ocean)
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
                .foregroundStyle(NauticalTheme.ocean)
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
                if messageText.count > ChatViewModel.maxMessageLength {
                    messageText = String(messageText.prefix(ChatViewModel.maxMessageLength))
                }
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
                .foregroundStyle(messageText.trimmingCharacters(in: .whitespaces).isEmpty ? .gray : NauticalTheme.ocean)
        }
        .disabled(messageText.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isSending || messageText.count > ChatViewModel.maxMessageLength)
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

// MARK: - Extracted Views (separate @Observable tracking scope)

/// Isolated view: only re-renders when messages, reactions, or senderProfiles change.
/// Typing indicator changes do NOT trigger re-render of the message list.
private struct ChatMessagesListView: View {
    let viewModel: ChatViewModel
    @Binding var showImageViewer: URL?
    @FocusState.Binding var isComposeFocused: Bool
    @Binding var messageText: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.messages.isEmpty {
                ProgressView("Loading messages...")
            } else if viewModel.messages.isEmpty {
                ContentUnavailableView(
                    "No Messages Yet",
                    systemImage: "text.bubble",
                    description: Text("Send the first message to start the conversation.")
                )
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            if viewModel.hasMore {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .onAppear {
                                        Task { await viewModel.loadMore() }
                                    }
                            }
                            ForEach(viewModel.messages.reversed(), id: \.id) { message in
                                messageRow(for: message)
                                    .id(message.id)
                                    .onAppear {
                                        Task { await viewModel.markMessageRead(message.id) }
                                    }
                                    .transition(reduceMotion ? .opacity : .asymmetric(
                                        insertion: .move(edge: .bottom).combined(with: .opacity),
                                        removal: .opacity
                                    ))
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .onChange(of: viewModel.messages.count) {
                        if let lastId = viewModel.messages.first?.id {
                            if reduceMotion {
                                proxy.scrollTo(lastId, anchor: .bottom)
                            } else {
                                withAnimation {
                                    proxy.scrollTo(lastId, anchor: .bottom)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func messageRow(for message: Message) -> some View {
        // Widget visitor messages have visitorName set — those are NOT from the current user (agent)
        let isOwn = message.visitorName == nil
            && message.senderId == SupabaseManager.shared.client.auth.currentUser?.id
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
}

/// Isolated view: only re-renders when typingUsers changes.
/// Message list changes do NOT trigger re-render of typing indicator.
private struct ChatTypingView: View {
    let viewModel: ChatViewModel

    var body: some View {
        TypingIndicator(userNames: viewModel.typingUsers.map { _ in "User" })
    }
}

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}

#if DEBUG
#Preview {
    ChatView(conversationId: PreviewData.dmConvId, title: "Alice Johnson")
}
#endif
