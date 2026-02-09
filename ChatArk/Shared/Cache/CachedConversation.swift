import Foundation
import SwiftData

@Model
final class CachedConversation {
    @Attribute(.unique) var conversationId: UUID
    var type: String
    var name: String?
    var avatarUrl: String?
    var updatedAt: Date
    var lastMessageContent: String?
    var lastMessageDate: Date?
    var unreadCount: Int

    init(
        conversationId: UUID,
        type: String,
        name: String? = nil,
        avatarUrl: String? = nil,
        updatedAt: Date = .now,
        lastMessageContent: String? = nil,
        lastMessageDate: Date? = nil,
        unreadCount: Int = 0
    ) {
        self.conversationId = conversationId
        self.type = type
        self.name = name
        self.avatarUrl = avatarUrl
        self.updatedAt = updatedAt
        self.lastMessageContent = lastMessageContent
        self.lastMessageDate = lastMessageDate
        self.unreadCount = unreadCount
    }
}
