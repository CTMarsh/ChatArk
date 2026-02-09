import Foundation
import SwiftData

@Model
final class CachedMessage {
    @Attribute(.unique) var messageId: UUID
    var conversationId: UUID
    var senderId: UUID
    var content: String
    var type: String
    var createdAt: Date
    var isEdited: Bool
    var isPinned: Bool
    var fileUrl: String?
    var fileName: String?
    var fileSize: Int64?
    var fileType: String?
    var deletedAt: Date?

    init(
        messageId: UUID,
        conversationId: UUID,
        senderId: UUID,
        content: String,
        type: String = "text",
        createdAt: Date = .now,
        isEdited: Bool = false,
        isPinned: Bool = false,
        fileUrl: String? = nil,
        fileName: String? = nil,
        fileSize: Int64? = nil,
        fileType: String? = nil,
        deletedAt: Date? = nil
    ) {
        self.messageId = messageId
        self.conversationId = conversationId
        self.senderId = senderId
        self.content = content
        self.type = type
        self.createdAt = createdAt
        self.isEdited = isEdited
        self.isPinned = isPinned
        self.fileUrl = fileUrl
        self.fileName = fileName
        self.fileSize = fileSize
        self.fileType = fileType
        self.deletedAt = deletedAt
    }

    func toMessage() -> Message {
        Message(
            id: messageId,
            conversationId: conversationId,
            senderId: senderId,
            content: content,
            type: MessageType(rawValue: type),
            isEdited: isEdited,
            createdAt: createdAt,
            fileUrl: fileUrl,
            fileName: fileName,
            fileSize: fileSize,
            fileType: fileType,
            deletedAt: deletedAt,
            isPinned: isPinned
        )
    }

    static func from(_ message: Message) -> CachedMessage {
        CachedMessage(
            messageId: message.id,
            conversationId: message.conversationId,
            senderId: message.senderId,
            content: message.content,
            type: message.type?.rawValue ?? "text",
            createdAt: message.createdAt ?? .now,
            isEdited: message.isEdited ?? false,
            isPinned: message.isPinned ?? false,
            fileUrl: message.fileUrl,
            fileName: message.fileName,
            fileSize: message.fileSize,
            fileType: message.fileType,
            deletedAt: message.deletedAt
        )
    }
}
