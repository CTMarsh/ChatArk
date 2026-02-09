import Foundation

struct Report: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    var sourceUserId: UUID
    var destUserId: UUID
    var reason: String
    var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case sourceUserId = "source_user_id"
        case destUserId = "dest_user_id"
        case reason
        case createdAt = "created_at"
    }
}
