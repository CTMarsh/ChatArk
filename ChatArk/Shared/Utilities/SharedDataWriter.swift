import Foundation
import CryptoKit
import os.log
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
    private let logger = Logger(subsystem: "com.chrismarsh.chatark", category: "SharedDataWriter")
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

        guard let data = try? encoder.encode(Array(summaries)) else {
            logger.error("Failed to encode conversation summaries")
            return
        }
        guard let encrypted = AppGroupEncryption.encrypt(data) else {
            logger.error("Failed to encrypt conversation data for App Group")
            return
        }
        defaults?.set(encrypted, forKey: "recent_conversations")
        defaults?.set(Date().timeIntervalSince1970, forKey: "conversations_updated_at")

        let totalUnread = details.reduce(0) { $0 + $1.unreadCount }
        defaults?.set(totalUnread, forKey: "total_unread_count")

        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }

    // MARK: - Current User (encrypted)

    func writeCurrentUser(id: String, name: String) {
        if let encryptedId = AppGroupEncryption.encryptString(id) {
            defaults?.set(encryptedId, forKey: "current_user_id")
        } else {
            logger.error("Failed to encrypt current_user_id for App Group")
        }
        if let encryptedName = AppGroupEncryption.encryptString(name) {
            defaults?.set(encryptedName, forKey: "current_user_name")
        } else {
            logger.error("Failed to encrypt current_user_name for App Group")
        }
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

    // MARK: - Auth Session (for watch companion, encrypted)

    func writeAuthSession(accessToken: String, refreshToken: String) {
        if let encryptedAccess = AppGroupEncryption.encryptString(accessToken) {
            defaults?.set(encryptedAccess, forKey: "auth_access_token")
        } else {
            logger.error("Failed to encrypt auth access token for App Group")
        }
        if let encryptedRefresh = AppGroupEncryption.encryptString(refreshToken) {
            defaults?.set(encryptedRefresh, forKey: "auth_refresh_token")
        } else {
            logger.error("Failed to encrypt auth refresh token for App Group")
        }
    }

    func clearAuthSession() {
        defaults?.removeObject(forKey: "auth_access_token")
        defaults?.removeObject(forKey: "auth_refresh_token")
    }

    static func readAuthSession() -> (accessToken: String, refreshToken: String)? {
        guard let defaults = UserDefaults(suiteName: "group.com.chrismarsh.chatark"),
              let encryptedAccess = defaults.data(forKey: "auth_access_token"),
              let encryptedRefresh = defaults.data(forKey: "auth_refresh_token"),
              let accessToken = AppGroupEncryption.decryptString(encryptedAccess),
              let refreshToken = AppGroupEncryption.decryptString(encryptedRefresh) else {
            return nil
        }
        return (accessToken, refreshToken)
    }

    // MARK: - Clear

    func clearAll() {
        let keys = ["recent_conversations", "total_unread_count", "current_user_id",
                     "current_user_name", "accent_color", "watch_unread_count",
                     "watch_recent_names", "watch_last_sync",
                     "auth_access_token", "auth_refresh_token",
                     "conversations_updated_at"]
        keys.forEach { defaults?.removeObject(forKey: $0) }

        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
}
