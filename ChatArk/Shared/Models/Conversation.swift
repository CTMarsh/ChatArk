import Foundation

enum ConversationType: String, Codable, Sendable {
    case direct
    case group
    case widget
}

struct Conversation: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    var type: ConversationType
    var name: String?
    var description: String?
    var avatarUrl: String?
    var createdBy: UUID?
    var createdAt: Date?
    var updatedAt: Date?
    var widgetId: UUID?
    var visitorSessionId: UUID?
    var endedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, type, name, description
        case avatarUrl = "avatar_url"
        case createdBy = "created_by"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case widgetId = "widget_id"
        case visitorSessionId = "visitor_session_id"
        case endedAt = "ended_at"
    }
}

struct ConversationParticipant: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    var conversationId: UUID
    var userId: UUID
    var role: String?
    var joinedAt: Date?
    var lastReadAt: Date?
    var notificationsEnabled: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case conversationId = "conversation_id"
        case userId = "user_id"
        case role
        case joinedAt = "joined_at"
        case lastReadAt = "last_read_at"
        case notificationsEnabled = "notifications_enabled"
    }
}

struct ConversationWithDetails: Identifiable, Hashable, Sendable {
    let conversation: Conversation
    var lastMessage: Message?
    var unreadCount: Int
    var participants: [Profile]

    var id: UUID { conversation.id }

    static func == (lhs: ConversationWithDetails, rhs: ConversationWithDetails) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
