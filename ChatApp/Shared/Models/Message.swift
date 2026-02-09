import Foundation

enum MessageType: String, Codable, Sendable {
    case text
    case image
    case file
    case system
}

struct Message: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    var conversationId: UUID
    var senderId: UUID
    var content: String
    var type: MessageType?
    var replyToId: UUID?
    var isEdited: Bool?
    var createdAt: Date?
    var updatedAt: Date?
    var fileUrl: String?
    var fileName: String?
    var fileSize: Int64?
    var fileType: String?
    var deletedAt: Date?
    var deletedBy: UUID?
    var isPinned: Bool?
    var pinnedAt: Date?
    var pinnedBy: UUID?
    var linkPreviews: [LinkPreview]?
    var visitorName: String?
    var visitorEmail: String?

    enum CodingKeys: String, CodingKey {
        case id
        case conversationId = "conversation_id"
        case senderId = "sender_id"
        case content, type
        case replyToId = "reply_to_id"
        case isEdited = "is_edited"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case fileUrl = "file_url"
        case fileName = "file_name"
        case fileSize = "file_size"
        case fileType = "file_type"
        case deletedAt = "deleted_at"
        case deletedBy = "deleted_by"
        case isPinned = "is_pinned"
        case pinnedAt = "pinned_at"
        case pinnedBy = "pinned_by"
        case linkPreviews = "link_previews"
        case visitorName = "visitor_name"
        case visitorEmail = "visitor_email"
    }

    var isDeleted: Bool {
        deletedAt != nil
    }

    var hasAttachment: Bool {
        fileUrl != nil
    }
}

struct LinkPreview: Codable, Hashable, Sendable {
    var url: String?
    var title: String?
    var description: String?
    var imageUrl: String?

    enum CodingKeys: String, CodingKey {
        case url, title, description
        case imageUrl = "image_url"
    }
}
