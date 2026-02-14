import Foundation

enum UserStatus: String, Codable, Sendable, CaseIterable {
    case online
    case offline
    case away
    case dnd
    case suspended
}

struct Profile: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    var username: String?
    var displayName: String?
    var avatarUrl: String?
    var status: UserStatus?
    var lastSeenAt: Date?
    var createdAt: Date?
    var updatedAt: Date?
    var email: String?
    var isPlatformAdmin: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
        case status
        case lastSeenAt = "last_seen_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case email
        case isPlatformAdmin = "is_platform_admin"
    }

    var displayLabel: String {
        displayName ?? username ?? email ?? "Unknown"
    }
}
