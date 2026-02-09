import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

// MARK: - Shared Types (written by main app, read by extensions)

struct SharedConversationSummary: Codable, Sendable {
    let id: String
    let name: String
    let avatarUrl: String?
    let lastMessageContent: String?
    let lastMessageDate: Date?
    let lastMessageSenderName: String?
    let unreadCount: Int
    let participantNames: [String]
    let type: String
}

struct PendingShare: Codable, Sendable {
    let id: String
    let conversationId: String
    let conversationName: String
    let items: [PendingShareItem]
    let createdAt: Date
}

struct PendingShareItem: Codable, Sendable {
    enum ItemType: String, Codable, Sendable {
        case text
        case url
        case image
        case file
    }

    let type: ItemType
    let text: String?
    let fileName: String?
}

// MARK: - SharedDataWriter

@MainActor
final class SharedDataWriter {
    static let shared = SharedDataWriter()

    private let suiteName = "group.com.chrismarsh.chatark"
    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    private var defaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    private init() {}

    // MARK: - Conversations

    func writeConversations(_ details: [ConversationWithDetails]) {
        let summaries = details.prefix(20).map { detail -> SharedConversationSummary in
            SharedConversationSummary(
                id: detail.id.uuidString,
                name: detail.conversation.name ?? detail.participants.map(\.displayLabel).joined(separator: ", "),
                avatarUrl: detail.conversation.avatarUrl,
                lastMessageContent: detail.lastMessage?.content,
                lastMessageDate: detail.lastMessage?.createdAt,
                lastMessageSenderName: nil,
                unreadCount: detail.unreadCount,
                participantNames: detail.participants.map(\.displayLabel),
                type: detail.conversation.type.rawValue
            )
        }

        guard let data = try? encoder.encode(Array(summaries)) else { return }
        defaults?.set(data, forKey: "recent_conversations")

        let totalUnread = details.reduce(0) { $0 + $1.unreadCount }
        defaults?.set(totalUnread, forKey: "total_unread_count")

        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }

    // MARK: - Current User

    func writeCurrentUser(id: String, name: String) {
        defaults?.set(id, forKey: "current_user_id")
        defaults?.set(name, forKey: "current_user_name")
    }

    // MARK: - Accent Color

    func writeAccentColor(_ hex: String) {
        defaults?.set(hex, forKey: "accent_color")
    }

    // MARK: - Watch Data

    func writeWatchData(unreadCount: Int, recentNames: [String]) {
        defaults?.set(unreadCount, forKey: "watch_unread_count")
        defaults?.set(recentNames, forKey: "watch_recent_names")
        defaults?.set(Date().timeIntervalSince1970, forKey: "watch_last_sync")
    }

    // MARK: - Clear

    func clearAll() {
        let keys = ["recent_conversations", "total_unread_count", "current_user_id",
                     "current_user_name", "accent_color", "watch_unread_count",
                     "watch_recent_names", "watch_last_sync"]
        keys.forEach { defaults?.removeObject(forKey: $0) }

        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
}
