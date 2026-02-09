import Foundation
import Supabase

@MainActor
final class ChatService {
    private let client: SupabaseClient

    nonisolated init(client: SupabaseClient = supabaseClient) {
        self.client = client
    }

    // MARK: - Fetch Messages

    func fetchMessages(
        conversationId: UUID,
        limit: Int = 50,
        before: Date? = nil
    ) async throws -> [Message] {
        var query = client.from("messages")
            .select()
            .eq("conversation_id", value: conversationId.uuidString)

        if let before {
            query = query.lt("created_at", value: ISO8601DateFormatter().string(from: before))
        }

        return try await query
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
    }

    // MARK: - Send Message

    func sendMessage(
        conversationId: UUID,
        content: String,
        type: MessageType = .text,
        replyToId: UUID? = nil,
        fileUrl: String? = nil,
        fileName: String? = nil,
        fileSize: Int64? = nil,
        fileType: String? = nil
    ) async throws -> Message {
        guard let userId = client.auth.currentUser?.id else {
            throw ChatError.notAuthenticated
        }

        var values: [String: AnyJSON] = [
            "conversation_id": .string(conversationId.uuidString),
            "sender_id": .string(userId.uuidString),
            "content": .string(content),
            "type": .string(type.rawValue),
        ]

        if let replyToId {
            values["reply_to_id"] = .string(replyToId.uuidString)
        }
        if let fileUrl {
            values["file_url"] = .string(fileUrl)
        }
        if let fileName {
            values["file_name"] = .string(fileName)
        }
        if let fileSize {
            values["file_size"] = .integer(Int(fileSize))
        }
        if let fileType {
            values["file_type"] = .string(fileType)
        }

        return try await client.from("messages")
            .insert(values)
            .select()
            .single()
            .execute()
            .value
    }

    // MARK: - Edit Message

    func editMessage(messageId: UUID, newContent: String) async throws -> Message {
        try await client.from("messages")
            .update([
                "content": AnyJSON.string(newContent),
                "is_edited": AnyJSON.bool(true),
                "updated_at": AnyJSON.string(ISO8601DateFormatter().string(from: Date())),
            ])
            .eq("id", value: messageId.uuidString)
            .select()
            .single()
            .execute()
            .value
    }

    // MARK: - Delete Message (Soft)

    func deleteMessage(messageId: UUID) async throws {
        guard let userId = client.auth.currentUser?.id else {
            throw ChatError.notAuthenticated
        }

        try await client.from("messages")
            .update([
                "deleted_at": AnyJSON.string(ISO8601DateFormatter().string(from: Date())),
                "deleted_by": AnyJSON.string(userId.uuidString),
            ])
            .eq("id", value: messageId.uuidString)
            .execute()
    }

    // MARK: - Pin / Unpin

    func pinMessage(messageId: UUID) async throws {
        guard let userId = client.auth.currentUser?.id else {
            throw ChatError.notAuthenticated
        }

        try await client.from("messages")
            .update([
                "is_pinned": AnyJSON.bool(true),
                "pinned_at": AnyJSON.string(ISO8601DateFormatter().string(from: Date())),
                "pinned_by": AnyJSON.string(userId.uuidString),
            ])
            .eq("id", value: messageId.uuidString)
            .execute()
    }

    func unpinMessage(messageId: UUID) async throws {
        try await client.from("messages")
            .update([
                "is_pinned": AnyJSON.bool(false),
                "pinned_at": AnyJSON.null,
                "pinned_by": AnyJSON.null,
            ])
            .eq("id", value: messageId.uuidString)
            .execute()
    }

    // MARK: - Reactions

    func addReaction(messageId: UUID, emoji: String) async throws -> MessageReaction {
        guard let userId = client.auth.currentUser?.id else {
            throw ChatError.notAuthenticated
        }

        return try await client.from("message_reactions")
            .insert([
                "message_id": AnyJSON.string(messageId.uuidString),
                "user_id": AnyJSON.string(userId.uuidString),
                "emoji": AnyJSON.string(emoji),
            ])
            .select()
            .single()
            .execute()
            .value
    }

    func removeReaction(reactionId: UUID) async throws {
        try await client.from("message_reactions")
            .delete()
            .eq("id", value: reactionId.uuidString)
            .execute()
    }

    func fetchReactions(messageId: UUID) async throws -> [MessageReaction] {
        try await client.from("message_reactions")
            .select()
            .eq("message_id", value: messageId.uuidString)
            .execute()
            .value
    }

    // MARK: - Mentions

    func addMention(messageId: UUID, mentionedUserId: UUID) async throws {
        try await client.from("message_mentions")
            .insert([
                "message_id": AnyJSON.string(messageId.uuidString),
                "mentioned_user_id": AnyJSON.string(mentionedUserId.uuidString),
            ])
            .execute()
    }

    func fetchMentions(messageId: UUID) async throws -> [MessageMention] {
        try await client.from("message_mentions")
            .select()
            .eq("message_id", value: messageId.uuidString)
            .execute()
            .value
    }

    // MARK: - Read Receipts

    func markAsRead(messageId: UUID) async throws {
        guard let userId = client.auth.currentUser?.id else {
            throw ChatError.notAuthenticated
        }

        try await client.from("message_read_receipts")
            .upsert([
                "message_id": AnyJSON.string(messageId.uuidString),
                "user_id": AnyJSON.string(userId.uuidString),
                "read_at": AnyJSON.string(ISO8601DateFormatter().string(from: Date())),
            ])
            .execute()
    }

    func fetchReadReceipts(messageId: UUID) async throws -> [MessageReadReceipt] {
        try await client.from("message_read_receipts")
            .select()
            .eq("message_id", value: messageId.uuidString)
            .execute()
            .value
    }

    // MARK: - Search

    func searchMessages(query: String, conversationId: UUID? = nil) async throws -> [Message] {
        var dbQuery = client.from("messages")
            .select()
            .textSearch("search_vector", query: query)

        if let conversationId {
            dbQuery = dbQuery.eq("conversation_id", value: conversationId.uuidString)
        }

        return try await dbQuery
            .order("created_at", ascending: false)
            .limit(50)
            .execute()
            .value
    }

    // MARK: - Pinned Messages

    func fetchPinnedMessages(conversationId: UUID) async throws -> [Message] {
        try await client.from("messages")
            .select()
            .eq("conversation_id", value: conversationId.uuidString)
            .eq("is_pinned", value: true)
            .order("pinned_at", ascending: false)
            .execute()
            .value
    }
}

// MARK: - Chat Errors

enum ChatError: LocalizedError {
    case notAuthenticated
    case messageSendFailed
    case messageNotFound
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: "You must be signed in to perform this action"
        case .messageSendFailed: "Failed to send message"
        case .messageNotFound: "Message not found"
        case .permissionDenied: "You don't have permission for this action"
        }
    }
}
