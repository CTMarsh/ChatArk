import Foundation

struct MessageReadReceipt: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    var messageId: UUID
    var userId: UUID
    var readAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case messageId = "message_id"
        case userId = "user_id"
        case readAt = "read_at"
    }
}
