import Foundation

struct VisitorSession: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    var widgetId: UUID
    var email: String?
    var name: String?
    var sessionToken: String?
    var metadata: [String: String]?
    var createdAt: Date?
    var lastSeenAt: Date?
    var expiresAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case widgetId = "widget_id"
        case email, name
        case sessionToken = "session_token"
        case metadata
        case createdAt = "created_at"
        case lastSeenAt = "last_seen_at"
        case expiresAt = "expires_at"
    }
}
