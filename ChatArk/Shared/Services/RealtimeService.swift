import Foundation
import Supabase
import Realtime

@MainActor
@Observable
final class RealtimeService {
    private let client: SupabaseClient
    private var channels: [String: RealtimeChannelV2] = [:]
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    // Published streams
    var onNewMessage: ((Message) -> Void)?
    var onMessageUpdate: ((Message) -> Void)?
    var onMessageDelete: ((Message) -> Void)?
    var onReactionChange: ((MessageReaction, ChangeAction) -> Void)?
    var onReadReceipt: ((MessageReadReceipt) -> Void)?
    var onConversationUpdate: ((Conversation) -> Void)?
    var onTypingEvent: ((UUID, UUID, Bool) -> Void)? // conversationId, userId, isTyping
    var onPresenceChange: ((UUID, UserStatus) -> Void)? // userId, status

    enum ChangeAction {
        case insert
        case update
        case delete
    }

    nonisolated init(client: SupabaseClient = supabaseClient) {
        self.client = client
    }

    // MARK: - Message Subscriptions

    func subscribeToMessages(conversationId: UUID) async {
        let channelKey = "messages:\(conversationId.uuidString)"
        guard channels[channelKey] == nil else { return }

        let channel = client.realtimeV2.channel(channelKey)

        let insertions = channel.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "messages",
            filter: .eq("conversation_id", value: conversationId.uuidString)
        )

        let updates = channel.postgresChange(
            UpdateAction.self,
            schema: "public",
            table: "messages",
            filter: .eq("conversation_id", value: conversationId.uuidString)
        )

        let deletions = channel.postgresChange(
            DeleteAction.self,
            schema: "public",
            table: "messages",
            filter: .eq("conversation_id", value: conversationId.uuidString)
        )

        channels[channelKey] = channel
        try? await channel.subscribeWithError()

        Task { [decoder] in
            for await insertion in insertions {
                if let message: Message = try? insertion.decodeRecord(decoder: decoder) {
                    await MainActor.run { self.onNewMessage?(message) }
                }
            }
        }

        Task { [decoder] in
            for await update in updates {
                if let message: Message = try? update.decodeRecord(decoder: decoder) {
                    await MainActor.run { self.onMessageUpdate?(message) }
                }
            }
        }

        Task { [decoder] in
            for await deletion in deletions {
                if let message: Message = try? deletion.decodeOldRecord(decoder: decoder) {
                    await MainActor.run { self.onMessageDelete?(message) }
                }
            }
        }
    }

    // MARK: - Reaction Subscriptions

    func subscribeToReactions(conversationId: UUID) async {
        let channelKey = "reactions:\(conversationId.uuidString)"
        guard channels[channelKey] == nil else { return }

        let channel = client.realtimeV2.channel(channelKey)

        let insertions = channel.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "message_reactions"
        )

        let deletions = channel.postgresChange(
            DeleteAction.self,
            schema: "public",
            table: "message_reactions"
        )

        channels[channelKey] = channel
        try? await channel.subscribeWithError()

        Task { [decoder] in
            for await insertion in insertions {
                if let reaction: MessageReaction = try? insertion.decodeRecord(decoder: decoder) {
                    await MainActor.run { self.onReactionChange?(reaction, .insert) }
                }
            }
        }

        Task { [decoder] in
            for await deletion in deletions {
                if let reaction: MessageReaction = try? deletion.decodeOldRecord(decoder: decoder) {
                    await MainActor.run { self.onReactionChange?(reaction, .delete) }
                }
            }
        }
    }

    // MARK: - Read Receipt Subscriptions

    func subscribeToReadReceipts(conversationId: UUID) async {
        let channelKey = "receipts:\(conversationId.uuidString)"
        guard channels[channelKey] == nil else { return }

        let channel = client.realtimeV2.channel(channelKey)

        let insertions = channel.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "message_read_receipts"
        )

        channels[channelKey] = channel
        try? await channel.subscribeWithError()

        Task { [decoder] in
            for await insertion in insertions {
                if let receipt: MessageReadReceipt = try? insertion.decodeRecord(decoder: decoder) {
                    await MainActor.run { self.onReadReceipt?(receipt) }
                }
            }
        }
    }

    // MARK: - Conversation Subscriptions

    func subscribeToConversations() async {
        let channelKey = "conversations"
        guard channels[channelKey] == nil else { return }

        let channel = client.realtimeV2.channel(channelKey)

        let updates = channel.postgresChange(
            UpdateAction.self,
            schema: "public",
            table: "conversations"
        )

        channels[channelKey] = channel
        try? await channel.subscribeWithError()

        Task { [decoder] in
            for await update in updates {
                if let conversation: Conversation = try? update.decodeRecord(decoder: decoder) {
                    await MainActor.run { self.onConversationUpdate?(conversation) }
                }
            }
        }
    }

    // MARK: - Typing Indicators (Broadcast)

    func subscribeToTyping(conversationId: UUID) async {
        let channelKey = "typing:\(conversationId.uuidString)"
        guard channels[channelKey] == nil else { return }

        let channel = client.realtimeV2.channel(channelKey)
        channels[channelKey] = channel
        try? await channel.subscribeWithError()

        Task {
            for await message in channel.broadcastStream(event: "typing") {
                if let userId = message["user_id"]?.stringValue,
                   let isTyping = message["is_typing"]?.boolValue,
                   let uuid = UUID(uuidString: userId) {
                    await MainActor.run {
                        self.onTypingEvent?(conversationId, uuid, isTyping)
                    }
                }
            }
        }
    }

    func sendTypingIndicator(conversationId: UUID, isTyping: Bool) async {
        guard let userId = client.auth.currentUser?.id else { return }
        let channelKey = "typing:\(conversationId.uuidString)"

        guard let channel = channels[channelKey] else { return }

        await channel.broadcast(
            event: "typing",
            message: [
                "user_id": .string(userId.uuidString),
                "is_typing": .bool(isTyping),
            ]
        )
    }

    // MARK: - Presence (Online Status)

    func subscribeToPresence() async {
        let channelKey = "presence"
        guard channels[channelKey] == nil else { return }

        let presenceKey = client.auth.currentUser?.id.uuidString ?? ""
        let channel = client.realtimeV2.channel(channelKey) { config in
            config.presence.key = presenceKey
        }
        channels[channelKey] = channel
        try? await channel.subscribeWithError()

        Task {
            for await action in channel.presenceChange() {
                for presence in action.joins {
                    if let userId = UUID(uuidString: presence.key) {
                        await MainActor.run {
                            self.onPresenceChange?(userId, .online)
                        }
                    }
                }
                for presence in action.leaves {
                    if let userId = UUID(uuidString: presence.key) {
                        await MainActor.run {
                            self.onPresenceChange?(userId, .offline)
                        }
                    }
                }
            }
        }
    }

    func trackPresence(status: UserStatus) async {
        let channelKey = "presence"
        guard let channel = channels[channelKey] else { return }

        try? await channel.track(["status": status.rawValue])
    }

    // MARK: - Reconnection

    func monitorConnection() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(10))
            guard NetworkMonitor.shared.isConnected else { continue }
            for (_, channel) in channels {
                if channel.status != .subscribed {
                    try? await channel.subscribeWithError()
                }
            }
        }
    }

    // MARK: - Unsubscribe

    func unsubscribe(channelKey: String) async {
        guard let channel = channels.removeValue(forKey: channelKey) else { return }
        await channel.unsubscribe()
    }

    func unsubscribeFromConversation(_ conversationId: UUID) async {
        let keys = [
            "messages:\(conversationId.uuidString)",
            "reactions:\(conversationId.uuidString)",
            "receipts:\(conversationId.uuidString)",
            "typing:\(conversationId.uuidString)",
        ]
        for key in keys {
            await unsubscribe(channelKey: key)
        }
    }

    func unsubscribeAll() async {
        for (_, channel) in channels {
            await channel.unsubscribe()
        }
        channels.removeAll()
    }
}
