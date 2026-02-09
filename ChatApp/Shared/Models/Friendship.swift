import Foundation

struct Friendship: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    var user1: UUID
    var user2: UUID
    var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case user1
        case user2
        case createdAt = "created_at"
    }
}
