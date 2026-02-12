import Foundation
import Supabase

@MainActor
final class ConversationService {
    private let client: SupabaseClient

    nonisolated init(client: SupabaseClient = supabaseClient) {
        self.client = client
    }

    // MARK: - Fetch Conversations

    func fetchConversations() async throws -> [Conversation] {
        guard let userId = client.auth.currentUser?.id else {
            throw ChatError.notAuthenticated
        }

        let participantRows: [ConversationParticipant] = try await client
            .from("conversation_participants")
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value

        let conversationIds = participantRows.map(\.conversationId.uuidString)
        guard !conversationIds.isEmpty else { return [] }

        return try await client.from("conversations")
            .select()
            .in("id", values: conversationIds)
            .order("updated_at", ascending: false)
            .execute()
            .value
    }

    func fetchConversation(id: UUID) async throws -> Conversation {
        try await client.from("conversations")
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value
    }

    // MARK: - Participants

    func fetchParticipants(conversationId: UUID) async throws -> [ConversationParticipant] {
        try await client.from("conversation_participants")
            .select()
            .eq("conversation_id", value: conversationId.uuidString)
            .execute()
            .value
    }

    func fetchParticipantProfiles(conversationId: UUID) async throws -> [Profile] {
        let participants = try await fetchParticipants(conversationId: conversationId)
        let userIds = participants.map(\.userId.uuidString)
        guard !userIds.isEmpty else { return [] }

        return try await client.from("profiles")
            .select()
            .in("id", values: userIds)
            .execute()
            .value
    }

    // MARK: - Create Conversations

    func createDirectConversation(otherUserId: UUID) async throws -> UUID {
        let response: AnyJSON = try await client.rpc(
            "create_direct_conversation",
            params: ["p_other_user_id": AnyJSON.string(otherUserId.uuidString)]
        ).execute().value

        guard case let .string(idString) = response,
              let uuid = UUID(uuidString: idString) else {
            throw ConversationError.createFailed
        }
        return uuid
    }

    func createGroupConversation(
        name: String,
        description: String? = nil,
        participantIds: [UUID]
    ) async throws -> Conversation {
        guard let userId = client.auth.currentUser?.id else {
            throw ChatError.notAuthenticated
        }

        let trimmedName = String(name.prefix(100))
        guard !trimmedName.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw ConversationError.createFailed
        }

        var conversationValues: [String: AnyJSON] = [
            "type": .string("group"),
            "name": .string(trimmedName),
            "created_by": .string(userId.uuidString),
        ]
        if let description {
            conversationValues["description"] = .string(String(description.prefix(500)))
        }

        let conversation: Conversation = try await client.from("conversations")
            .insert(conversationValues)
            .select()
            .single()
            .execute()
            .value

        var allParticipants = participantIds
        if !allParticipants.contains(userId) {
            allParticipants.insert(userId, at: 0)
        }

        let participantRows: [[String: AnyJSON]] = allParticipants.map { pid in
            var row: [String: AnyJSON] = [
                "conversation_id": .string(conversation.id.uuidString),
                "user_id": .string(pid.uuidString),
            ]
            if pid == userId {
                row["role"] = .string("admin")
            }
            return row
        }

        try await client.from("conversation_participants")
            .insert(participantRows)
            .execute()

        return conversation
    }

    // MARK: - Update Participant

    func updateLastReadAt(conversationId: UUID) async throws {
        guard let userId = client.auth.currentUser?.id else {
            throw ChatError.notAuthenticated
        }

        try await client.from("conversation_participants")
            .update(["last_read_at": AnyJSON.string(ISO8601DateFormatter().string(from: Date()))])
            .eq("conversation_id", value: conversationId.uuidString)
            .eq("user_id", value: userId.uuidString)
            .execute()
    }

    func updateParticipantRole(conversationId: UUID, userId: UUID, role: ParticipantRole) async throws {
        try await client.from("conversation_participants")
            .update(["role": AnyJSON.string(role.rawValue)])
            .eq("conversation_id", value: conversationId.uuidString)
            .eq("user_id", value: userId.uuidString)
            .execute()
    }

    func addParticipant(conversationId: UUID, userId: UUID) async throws {
        try await client.from("conversation_participants")
            .insert([
                "conversation_id": AnyJSON.string(conversationId.uuidString),
                "user_id": AnyJSON.string(userId.uuidString),
            ])
            .execute()
    }

    func removeParticipant(conversationId: UUID, userId: UUID) async throws {
        try await client.from("conversation_participants")
            .delete()
            .eq("conversation_id", value: conversationId.uuidString)
            .eq("user_id", value: userId.uuidString)
            .execute()
    }

    // MARK: - Unread Count

    func getUnreadCount(conversationId: UUID) async throws -> Int {
        guard let userId = client.auth.currentUser?.id else {
            throw ChatError.notAuthenticated
        }

        let response: AnyJSON = try await client.rpc(
            "get_unread_count",
            params: [
                "conv_id": AnyJSON.string(conversationId.uuidString),
                "usr_id": AnyJSON.string(userId.uuidString),
            ]
        ).execute().value

        if case let .integer(count) = response {
            return count
        }
        return 0
    }

    // MARK: - Last Message

    func fetchLastMessage(conversationId: UUID) async throws -> Message? {
        let messages: [Message] = try await client.from("messages")
            .select()
            .eq("conversation_id", value: conversationId.uuidString)
            .order("created_at", ascending: false)
            .limit(1)
            .execute()
            .value

        return messages.first
    }

    // MARK: - Update Conversation

    func updateConversation(id: UUID, name: String? = nil, description: String? = nil, avatarUrl: String? = nil) async throws {
        var updates: [String: AnyJSON] = [:]
        if let name { updates["name"] = .string(name) }
        if let description { updates["description"] = .string(description) }
        if let avatarUrl { updates["avatar_url"] = .string(avatarUrl) }

        guard !updates.isEmpty else { return }

        try await client.from("conversations")
            .update(updates)
            .eq("id", value: id.uuidString)
            .execute()
    }
}

// MARK: - Errors

enum ParticipantRole: String, Sendable {
    case admin
    case moderator
    case member
}

enum ConversationError: LocalizedError {
    case createFailed
    case notFound
    case notParticipant

    var errorDescription: String? {
        switch self {
        case .createFailed: "Failed to create conversation"
        case .notFound: "Conversation not found"
        case .notParticipant: "You are not a participant in this conversation"
        }
    }
}
