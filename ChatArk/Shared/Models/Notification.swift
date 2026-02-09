import Foundation

enum NotificationType: String, Codable, Sendable {
    case newMessage = "new_message"
    case groupInvite = "group_invite"
    case mention
}

struct AppNotification: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    var userId: UUID
    var type: NotificationType
    var title: String
    var body: String?
    var data: NotificationData?
    var isRead: Bool?
    var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case type, title, body, data
        case isRead = "is_read"
        case createdAt = "created_at"
    }
}

struct NotificationData: Codable, Hashable, Sendable {
    var conversationId: String?
    var messageId: String?
    var senderId: String?
    var senderName: String?

    enum CodingKeys: String, CodingKey {
        case conversationId = "conversation_id"
        case messageId = "message_id"
        case senderId = "sender_id"
        case senderName = "sender_name"
    }
}
