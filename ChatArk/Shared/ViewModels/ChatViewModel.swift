import Foundation
import SwiftUI
import Supabase

enum ChatViewError: LocalizedError {
    case networkUnavailable
    case sessionExpired
    case fileTooLarge(maxMB: Int)
    case uploadFailed(String)
    case sendFailed(String)
    case loadFailed(String)
    case messageTooLong(Int)
    case generic(String)

    var errorDescription: String? {
        switch self {
        case .networkUnavailable: "No internet connection. Your message will be sent when you're back online."
        case .sessionExpired: "Your session has expired. Please sign in again."
        case .fileTooLarge(let maxMB): "File exceeds the \(maxMB)MB limit. Please choose a smaller file."
        case .messageTooLong(let max): "Message exceeds the \(max) character limit."
        case .uploadFailed(let detail): "Failed to upload file: \(detail)"
        case .sendFailed(let detail): "Failed to send message: \(detail)"
        case .loadFailed(let detail): "Failed to load messages: \(detail)"
        case .generic(let detail): detail
        }
    }
}

@MainActor
@Observable
final class ChatViewModel {
    var messages: [Message] = []
    var reactions: [UUID: [ReactionGroup]] = [:]
    var typingUsers: [UUID] = []
    var isLoading = false
    var isSending = false
    var error: String?
    var chatError: ChatViewError?
    var hasMore = true
    var replyingTo: Message?
    var editingMessage: Message?
    var pinnedMessages: [Message] = []
    var senderProfiles: [UUID: Profile] = [:]
    var failedMessageIds: Set<UUID> = []
    var sendingMessageIds: Set<UUID> = []

    static let maxMessageLength = 10_000

    let conversationId: UUID
    private let chatService: ChatService
    // Rate limit: 10 messages burst, 1 per second refill
    private let sendRateLimiter = RateLimiter(maxTokens: 10, refillInterval: 1.0)
    private let conversationService: ConversationService
    private let realtimeService: RealtimeService
    private let presenceService: PresenceService
    private var currentUserId: UUID?
    private var reconnectionTask: Task<Void, Never>?

    init(
        conversationId: UUID,
        chatService: ChatService = ChatService(),
        conversationService: ConversationService = ConversationService(),
        realtimeService: RealtimeService = RealtimeService(),
        presenceService: PresenceService = PresenceService()
    ) {
        self.conversationId = conversationId
        self.chatService = chatService
        self.conversationService = conversationService
        self.realtimeService = realtimeService
        self.presenceService = presenceService
        self.currentUserId = SupabaseManager.shared.client.auth.currentUser?.id
    }

    // MARK: - Load Messages

    func loadMessages() async {
        isLoading = true
        error = nil
        chatError = nil
        defer { isLoading = false }

        do {
            messages = try await chatService.fetchMessages(conversationId: conversationId)
            pinnedMessages = try await chatService.fetchPinnedMessages(conversationId: conversationId)
            try await conversationService.updateLastReadAt(conversationId: conversationId)
            await fetchSenderProfiles(for: messages)
        } catch {
            let desc = ErrorSanitizer.sanitize(error)
            self.error = desc
            if !NetworkMonitor.shared.isConnected {
                chatError = .networkUnavailable
            } else {
                chatError = .loadFailed(desc)
            }
        }
    }

    func loadMore() async {
        guard hasMore, !isLoading, let oldestMessage = messages.last else { return }

        do {
            let older = try await chatService.fetchMessages(
                conversationId: conversationId,
                before: oldestMessage.createdAt
            )
            if older.isEmpty {
                hasMore = false
            } else {
                messages.append(contentsOf: older)
            }
        } catch {
            self.error = ErrorSanitizer.sanitize(error)
        }
    }

    // MARK: - Subscribe

    func subscribe() async {
        async let msgs: Void = realtimeService.subscribeToMessages(conversationId: conversationId)
        async let reactions: Void = realtimeService.subscribeToReactions(conversationId: conversationId)
        async let receipts: Void = realtimeService.subscribeToReadReceipts(conversationId: conversationId)
        async let typing: Void = realtimeService.subscribeToTyping(conversationId: conversationId)
        _ = await (msgs, reactions, receipts, typing)

        realtimeService.onNewMessage = { [weak self] message in
            guard let self, message.conversationId == self.conversationId else { return }
            Task { @MainActor in
                // Deduplicate: skip if already inserted optimistically
                guard !self.messages.contains(where: { $0.id == message.id }) else { return }
                self.messages.insert(message, at: 0)
                try? await self.conversationService.updateLastReadAt(conversationId: self.conversationId)
                await self.fetchSenderProfiles(for: [message])
            }
        }

        realtimeService.onMessageUpdate = { [weak self] message in
            guard let self else { return }
            Task { @MainActor in
                if let index = self.messages.firstIndex(where: { $0.id == message.id }) {
                    self.messages[index] = message
                }
                if message.isPinned == true {
                    if !self.pinnedMessages.contains(where: { $0.id == message.id }) {
                        self.pinnedMessages.insert(message, at: 0)
                    }
                } else {
                    self.pinnedMessages.removeAll { $0.id == message.id }
                }
            }
        }

        realtimeService.onMessageDelete = { [weak self] message in
            guard let self else { return }
            Task { @MainActor in
                if let index = self.messages.firstIndex(where: { $0.id == message.id }) {
                    self.messages[index] = message
                }
            }
        }

        realtimeService.onReactionChange = { [weak self] reaction, action in
            guard let self else { return }
            Task { @MainActor in
                self.updateReactionGroups(for: reaction.messageId)
            }
        }

        realtimeService.onTypingEvent = { [weak self] convId, userId, isTyping in
            guard let self, convId == self.conversationId, userId != self.currentUserId else { return }
            Task { @MainActor in
                if isTyping {
                    if !self.typingUsers.contains(userId) {
                        self.typingUsers.append(userId)
                    }
                } else {
                    self.typingUsers.removeAll { $0 == userId }
                }
            }
        }

        reconnectionTask = Task { await realtimeService.monitorConnection() }
    }

    func unsubscribe() async {
        reconnectionTask?.cancel()
        await realtimeService.unsubscribeFromConversation(conversationId)
    }

    // MARK: - Send Message (Optimistic)

    func sendMessage(content: String, type: MessageType = .text, fileUrl: String? = nil, fileName: String? = nil, fileSize: Int64? = nil, fileType: String? = nil) async {
        guard let userId = currentUserId else {
            chatError = .sessionExpired
            return
        }

        guard content.count <= Self.maxMessageLength else {
            chatError = .messageTooLong(Self.maxMessageLength)
            return
        }

        guard sendRateLimiter.tryConsume() else {
            chatError = .generic("Sending too fast. Please wait a moment.")
            return
        }

        if !NetworkMonitor.shared.isConnected {
            chatError = .networkUnavailable
        }

        // Create optimistic local message
        let placeholderId = UUID()
        let placeholder = Message(
            id: placeholderId,
            conversationId: conversationId,
            senderId: userId,
            content: content,
            type: type,
            replyToId: replyingTo?.id,
            createdAt: Date(),
            fileUrl: fileUrl,
            fileName: fileName,
            fileSize: fileSize,
            fileType: fileType
        )

        // Insert optimistically before API call
        sendingMessageIds.insert(placeholderId)
        messages.insert(placeholder, at: 0)
        let savedReplyTo = replyingTo
        replyingTo = nil
        isSending = true

        do {
            let realMessage = try await chatService.sendMessage(
                conversationId: conversationId,
                content: content,
                type: type,
                replyToId: savedReplyTo?.id,
                fileUrl: fileUrl,
                fileName: fileName,
                fileSize: fileSize,
                fileType: fileType
            )
            // Replace placeholder with real message from server
            sendingMessageIds.remove(placeholderId)
            if let index = messages.firstIndex(where: { $0.id == placeholderId }) {
                messages[index] = realMessage
            }
            chatError = nil
        } catch {
            // Mark as failed — keep in list so user can retry
            sendingMessageIds.remove(placeholderId)
            failedMessageIds.insert(placeholderId)
            let desc = ErrorSanitizer.sanitize(error)
            if desc.lowercased().contains("jwt") || desc.lowercased().contains("auth") {
                chatError = .sessionExpired
            } else {
                chatError = .sendFailed(desc)
            }
            self.error = desc
        }

        isSending = false
    }

    func retryMessage(_ messageId: UUID) async {
        guard let index = messages.firstIndex(where: { $0.id == messageId }),
              failedMessageIds.contains(messageId) else { return }

        let message = messages[index]
        failedMessageIds.remove(messageId)
        messages.remove(at: index)

        await sendMessage(
            content: message.content,
            type: message.type ?? .text,
            fileUrl: message.fileUrl,
            fileName: message.fileName,
            fileSize: message.fileSize,
            fileType: message.fileType
        )
    }

    func discardFailedMessage(_ messageId: UUID) {
        failedMessageIds.remove(messageId)
        messages.removeAll { $0.id == messageId }
    }

    // MARK: - Edit Message

    func editMessage(messageId: UUID, newContent: String) async {
        do {
            _ = try await chatService.editMessage(messageId: messageId, newContent: newContent)
            editingMessage = nil
        } catch {
            self.error = ErrorSanitizer.sanitize(error)
        }
    }

    // MARK: - Delete Message

    func deleteMessage(messageId: UUID) async {
        do {
            try await chatService.deleteMessage(messageId: messageId)
        } catch {
            self.error = ErrorSanitizer.sanitize(error)
        }
    }

    // MARK: - Reactions

    func addReaction(messageId: UUID, emoji: String) async {
        do {
            _ = try await chatService.addReaction(messageId: messageId, emoji: emoji)
        } catch {
            self.error = ErrorSanitizer.sanitize(error)
        }
    }

    func removeReaction(reactionId: UUID) async {
        do {
            try await chatService.removeReaction(reactionId: reactionId)
        } catch {
            self.error = ErrorSanitizer.sanitize(error)
        }
    }

    // MARK: - Pin / Unpin

    func pinMessage(messageId: UUID) async {
        do {
            try await chatService.pinMessage(messageId: messageId)
        } catch {
            self.error = ErrorSanitizer.sanitize(error)
        }
    }

    func unpinMessage(messageId: UUID) async {
        do {
            try await chatService.unpinMessage(messageId: messageId)
        } catch {
            self.error = ErrorSanitizer.sanitize(error)
        }
    }

    // MARK: - Read Receipts

    func markMessageRead(_ messageId: UUID) async {
        guard let userId = currentUserId else { return }
        // Only mark others' messages as read
        guard let message = messages.first(where: { $0.id == messageId }),
              message.senderId != userId else { return }
        do {
            try await chatService.markAsRead(messageId: messageId)
        } catch {}
    }

    // MARK: - Typing Indicator

    func sendTypingIndicator(isTyping: Bool) async {
        await realtimeService.sendTypingIndicator(conversationId: conversationId, isTyping: isTyping)
    }

    // MARK: - Private

    private func updateReactionGroups(for messageId: UUID) {
        Task {
            guard let allReactions = try? await chatService.fetchReactions(messageId: messageId) else { return }
            var groups: [String: ReactionGroup] = [:]

            for reaction in allReactions {
                if var group = groups[reaction.emoji] {
                    group.count += 1
                    group.userIds.append(reaction.userId)
                    if reaction.userId == currentUserId {
                        group.currentUserReacted = true
                    }
                    groups[reaction.emoji] = group
                } else {
                    groups[reaction.emoji] = ReactionGroup(
                        emoji: reaction.emoji,
                        count: 1,
                        userIds: [reaction.userId],
                        currentUserReacted: reaction.userId == currentUserId
                    )
                }
            }

            reactions[messageId] = Array(groups.values).sorted { $0.emoji < $1.emoji }
        }
    }

    private func fetchSenderProfiles(for messages: [Message]) async {
        let unknownSenderIds = Array(Set(messages.map(\.senderId)).subtracting(senderProfiles.keys))
        guard !unknownSenderIds.isEmpty else { return }

        let profiles = (try? await presenceService.fetchProfiles(userIds: unknownSenderIds)) ?? []
        for profile in profiles {
            senderProfiles[profile.id] = profile
        }
    }
}
