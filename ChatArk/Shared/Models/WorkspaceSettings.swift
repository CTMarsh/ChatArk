import Foundation

struct BusinessHourDay: Codable, Hashable, Sendable {
    var start: String
    var end: String
    var enabled: Bool
}

struct WorkspaceSettings: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    var workspaceId: UUID
    var defaultPrimaryColor: String?
    var defaultWelcomeMessage: String?
    var defaultOfflineMessage: String?
    var businessHoursEnabled: Bool
    var businessHours: [String: BusinessHourDay]?
    var timezone: String?
    var autoReplyEnabled: Bool
    var autoReplyMessage: String?
    var maxConversationsPerAgent: Int?
    var notifyOnNewConversation: Bool
    var notifyOnUnassignedTimeout: Bool
    var unassignedTimeoutMinutes: Int?
    var createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case workspaceId = "workspace_id"
        case defaultPrimaryColor = "default_primary_color"
        case defaultWelcomeMessage = "default_welcome_message"
        case defaultOfflineMessage = "default_offline_message"
        case businessHoursEnabled = "business_hours_enabled"
        case businessHours = "business_hours"
        case timezone
        case autoReplyEnabled = "auto_reply_enabled"
        case autoReplyMessage = "auto_reply_message"
        case maxConversationsPerAgent = "max_conversations_per_agent"
        case notifyOnNewConversation = "notify_on_new_conversation"
        case notifyOnUnassignedTimeout = "notify_on_unassigned_timeout"
        case unassignedTimeoutMinutes = "unassigned_timeout_minutes"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
