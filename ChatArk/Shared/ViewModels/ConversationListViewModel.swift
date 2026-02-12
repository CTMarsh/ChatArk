import Foundation
import SwiftUI
#if canImport(WatchConnectivity)
import WatchConnectivity
#endif

@MainActor
@Observable
final class ConversationListViewModel {
    var conversations: [ConversationWithDetails] = []
    var isLoading = false
    var error: String?
    var searchQuery = ""

    private let conversationService: ConversationService
    private let chatService: ChatService
    private let presenceService: PresenceService
    private let realtimeService: RealtimeService
    private var sortDebounceTask: Task<Void, Never>?

    init(
        conversationService: ConversationService = ConversationService(),
        chatService: ChatService = ChatService(),
        presenceService: PresenceService = PresenceService(),
        realtimeService: RealtimeService = RealtimeService()
    ) {
        self.conversationService = conversationService
        self.chatService = chatService
        self.presenceService = presenceService
        self.realtimeService = realtimeService
    }

    // MARK: - Load

    func loadConversations() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let rawConversations = try await conversationService.fetchConversations()

            let details: [ConversationWithDetails] = await withTaskGroup(
                of: ConversationWithDetails?.self,
                returning: [ConversationWithDetails].self
            ) { group in
                for conversation in rawConversations {
                    group.addTask { [conversationService] in
                        async let lastMessage = try? conversationService.fetchLastMessage(conversationId: conversation.id)
                        async let unreadCount = (try? conversationService.getUnreadCount(conversationId: conversation.id)) ?? 0
                        async let participants = (try? conversationService.fetchParticipantProfiles(conversationId: conversation.id)) ?? []

                        return ConversationWithDetails(
                            conversation: conversation,
                            lastMessage: await lastMessage,
                            unreadCount: await unreadCount,
                            participants: await participants
                        )
                    }
                }

                var results: [ConversationWithDetails] = []
                for await result in group {
                    if let result { results.append(result) }
                }
                return results
            }

            conversations = details.sorted {
                let d1 = $0.lastMessage?.createdAt ?? $0.conversation.createdAt ?? .distantPast
                let d2 = $1.lastMessage?.createdAt ?? $1.conversation.createdAt ?? .distantPast
                return d1 > d2
            }
            SharedDataWriter.shared.writeConversations(conversations)
            syncWatchData()
        } catch {
            self.error = ErrorSanitizer.sanitize(error)
        }
    }

    // MARK: - Subscribe to Real-time

    func subscribe() async {
        await realtimeService.subscribeToConversations()

        realtimeService.onConversationUpdate = { [weak self] conversation in
            guard let self else { return }
            Task { @MainActor in
                if let index = self.conversations.firstIndex(where: { $0.id == conversation.id }) {
                    self.conversations[index] = ConversationWithDetails(
                        conversation: conversation,
                        lastMessage: self.conversations[index].lastMessage,
                        unreadCount: self.conversations[index].unreadCount,
                        participants: self.conversations[index].participants
                    )
                }
            }
        }

        realtimeService.onNewMessage = { [weak self] message in
            guard let self else { return }
            Task { @MainActor in
                if let index = self.conversations.firstIndex(where: { $0.id == message.conversationId }) {
                    var updated = self.conversations[index]
                    updated = ConversationWithDetails(
                        conversation: updated.conversation,
                        lastMessage: message,
                        unreadCount: updated.unreadCount + 1,
                        participants: updated.participants
                    )
                    self.conversations[index] = updated
                    self.debouncedSortAndWrite()
                }
            }
        }
    }

    // MARK: - Create Conversations

    func createDirectConversation(otherUserId: UUID) async throws -> UUID {
        try await conversationService.createDirectConversation(otherUserId: otherUserId)
    }

    func createGroupConversation(name: String, participantIds: [UUID]) async throws -> Conversation {
        let conversation = try await conversationService.createGroupConversation(
            name: name,
            participantIds: participantIds
        )
        await loadConversations()
        return conversation
    }

    // MARK: - Delete

    func deleteConversation(_ detail: ConversationWithDetails, currentUserId: UUID) async {
        do {
            try await conversationService.removeParticipant(
                conversationId: detail.id,
                userId: currentUserId
            )
        } catch {
            self.error = ErrorSanitizer.sanitize(error)
        }
        conversations.removeAll { $0.id == detail.id }
        SharedDataWriter.shared.writeConversations(conversations)
    }

    // MARK: - Filtered

    var filteredConversations: [ConversationWithDetails] {
        guard !searchQuery.isEmpty else { return conversations }
        return conversations.filter { detail in
            if let name = detail.conversation.name?.lowercased(),
               name.contains(searchQuery.lowercased()) {
                return true
            }
            return detail.participants.contains { profile in
                profile.displayLabel.lowercased().contains(searchQuery.lowercased())
            }
        }
    }

    var totalUnreadCount: Int {
        conversations.reduce(0) { $0 + $1.unreadCount }
    }

    // MARK: - Private

    private func sortConversations() {
        conversations.sort {
            let d1 = $0.lastMessage?.createdAt ?? $0.conversation.createdAt ?? .distantPast
            let d2 = $1.lastMessage?.createdAt ?? $1.conversation.createdAt ?? .distantPast
            return d1 > d2
        }
    }

    private func debouncedSortAndWrite() {
        sortDebounceTask?.cancel()
        sortDebounceTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            sortConversations()
            SharedDataWriter.shared.writeConversations(conversations)
            syncWatchData()
        }
    }

    private func syncWatchData() {
        let count = totalUnreadCount
        let names = conversations.prefix(3).map {
            $0.conversation.name ?? $0.participants.first?.displayLabel ?? "Unknown"
        }
        SharedDataWriter.shared.writeWatchData(unreadCount: count, recentNames: names)
        #if os(iOS)
        WatchConnectivityManager.shared.sendUnreadCount(count, recentNames: names)
        #endif
    }
}
