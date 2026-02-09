import Foundation

struct UserSession: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    var userId: UUID
    var sessionToken: String
    var deviceInfo: [String: String]?
    var ipAddress: String?
    var userAgent: String?
    var lastActiveAt: Date?
    var createdAt: Date?
    var expiresAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case sessionToken = "session_token"
        case deviceInfo = "device_info"
        case ipAddress = "ip_address"
        case userAgent = "user_agent"
        case lastActiveAt = "last_active_at"
        case createdAt = "created_at"
        case expiresAt = "expires_at"
    }
}
