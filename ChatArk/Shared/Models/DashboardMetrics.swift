import Foundation

struct DashboardMetrics: Codable, Sendable {
    var totalUsers: Int
    var activeToday: Int
    var totalWorkspaces: Int
    var totalWidgets: Int
    var totalConversations: Int
    var conversationsToday: Int
    var totalMessages: Int
    var messagesToday: Int

    enum CodingKeys: String, CodingKey {
        case totalUsers = "total_users"
        case activeToday = "active_today"
        case totalWorkspaces = "total_workspaces"
        case totalWidgets = "total_widgets"
        case totalConversations = "total_conversations"
        case conversationsToday = "conversations_today"
        case totalMessages = "total_messages"
        case messagesToday = "messages_today"
    }
}
