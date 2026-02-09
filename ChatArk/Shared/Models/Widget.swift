import Foundation

struct WorkspaceWidget: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    var workspaceId: UUID
    var name: String
    var embedToken: String?
    var allowedOrigins: [String]?
    var primaryColor: String?
    var position: String?
    var welcomeMessage: String?
    var offlineMessage: String?
    var requireEmail: Bool?
    var collectName: Bool?
    var isActive: Bool?
    var createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case workspaceId = "workspace_id"
        case name
        case embedToken = "embed_token"
        case allowedOrigins = "allowed_origins"
        case primaryColor = "primary_color"
        case position
        case welcomeMessage = "welcome_message"
        case offlineMessage = "offline_message"
        case requireEmail = "require_email"
        case collectName = "collect_name"
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
