import Foundation

struct MessageReaction: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    var messageId: UUID
    var userId: UUID
    var emoji: String
    var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case messageId = "message_id"
        case userId = "user_id"
        case emoji
        case createdAt = "created_at"
    }
}

struct ReactionGroup: Identifiable, Hashable, Sendable {
    let emoji: String
    var count: Int
    var userIds: [UUID]
    var currentUserReacted: Bool

    var id: String { emoji }
}
