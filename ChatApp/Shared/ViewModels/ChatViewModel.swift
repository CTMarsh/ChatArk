import Foundation
import SwiftUI
import Supabase

@MainActor
@Observable
final class ChatViewModel {
    var messages: [Message] = []
    var reactions: [UUID: [ReactionGroup]] = [:]
    var typingUsers: [UUID] = []
    var isLoading = false
    var isSending = false
    var error: String?
    var hasMore = true
    var replyingTo: Message?
    var editingMessage: Message?
    var pinnedMessages: [Message] = []
    var senderProfiles: [UUID: Profile] = [:]

    let conversationId: UUID
    private let chatService: ChatService
    private let conversationService: ConversationService
    private let realtimeService: RealtimeService
    private let presenceService: PresenceService
    private var currentUserId: UUID?

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
        defer { isLoading = false }

        do {
            messages = try await chatService.fetchMessages(conversationId: conversationId)
            pinnedMessages = try await chatService.fetchPinnedMessages(conversationId: conversationId)
            try await conversationService.updateLastReadAt(conversationId: conversationId)
            await fetchSenderProfiles(for: messages)
        } catch {
            self.error = error.localizedDescription
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
            self.error = error.localizedDescription
        }
    }

    // MARK: - Subscribe

    func subscribe() async {
        await realtimeService.subscribeToMessages(conversationId: conversationId)
        await realtimeService.subscribeToReactions(conversationId: conversationId)
        await realtimeService.subscribeToReadReceipts(conversationId: conversationId)
        await realtimeService.subscribeToTyping(conversationId: conversationId)

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
    }

    func unsubscribe() async {
        await realtimeService.unsubscribeFromConversation(conversationId)
    }

    // MARK: - Send Message

    func sendMessage(content: String, type: MessageType = .text, fileUrl: String? = nil, fileName: String? = nil, fileSize: Int64? = nil, fileType: String? = nil) async {
        isSending = true
        defer { isSending = false }

        do {
            let message = try await chatService.sendMessage(
                conversationId: conversationId,
                content: content,
                type: type,
                replyToId: replyingTo?.id,
                fileUrl: fileUrl,
                fileName: fileName,
                fileSize: fileSize,
                fileType: fileType
            )
            replyingTo = nil
            // Insert immediately so the message appears without waiting for realtime
            if !messages.contains(where: { $0.id == message.id }) {
                messages.insert(message, at: 0)
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Edit Message

    func editMessage(messageId: UUID, newContent: String) async {
        do {
            _ = try await chatService.editMessage(messageId: messageId, newContent: newContent)
            editingMessage = nil
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Delete Message

    func deleteMessage(messageId: UUID) async {
        do {
            try await chatService.deleteMessage(messageId: messageId)
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Reactions

    func addReaction(messageId: UUID, emoji: String) async {
        do {
            _ = try await chatService.addReaction(messageId: messageId, emoji: emoji)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func removeReaction(reactionId: UUID) async {
        do {
            try await chatService.removeReaction(reactionId: reactionId)
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Pin / Unpin

    func pinMessage(messageId: UUID) async {
        do {
            try await chatService.pinMessage(messageId: messageId)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func unpinMessage(messageId: UUID) async {
        do {
            try await chatService.unpinMessage(messageId: messageId)
        } catch {
            self.error = error.localizedDescription
        }
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
        let unknownSenderIds = Set(messages.map(\.senderId)).subtracting(senderProfiles.keys)
        for senderId in unknownSenderIds {
            if let profile = try? await presenceService.fetchProfile(userId: senderId) {
                senderProfiles[senderId] = profile
            }
        }
    }
}
