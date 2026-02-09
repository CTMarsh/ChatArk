import Foundation

struct MessageMention: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    var messageId: UUID
    var mentionedUserId: UUID
    var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case messageId = "message_id"
        case mentionedUserId = "mentioned_user_id"
        case createdAt = "created_at"
    }
}
