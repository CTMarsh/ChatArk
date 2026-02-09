import Foundation

struct BlockedUser: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    var userId: UUID
    var blockedUserId: UUID
    var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case blockedUserId = "blocked_user_id"
        case createdAt = "created_at"
    }
}
