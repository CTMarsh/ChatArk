import Foundation

enum Theme: String, Codable, Sendable, CaseIterable {
    case light
    case dark
    case system
}

enum UIScale: String, Codable, Sendable, CaseIterable {
    case compact
    case comfortable
    case spacious
}

enum FontSize: String, Codable, Sendable, CaseIterable {
    case small
    case medium
    case large
}

enum MessageDensity: String, Codable, Sendable, CaseIterable {
    case compact
    case `default`
    case relaxed
}

enum EnterKeyBehavior: String, Codable, Sendable, CaseIterable {
    case send
    case newline
}

enum EmojiSkinTone: String, Codable, Sendable, CaseIterable {
    case `default`
    case light
    case mediumLight = "medium-light"
    case medium
    case mediumDark = "medium-dark"
    case dark
}

struct UserPreferences: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    var userId: UUID
    var bio: String?
    var onlineStatusPreference: String?
    var theme: Theme?
    var uiScale: UIScale?
    var fontSize: FontSize?
    var accentColor: String?
    var messageDensity: MessageDensity?
    var enterKeyBehavior: EnterKeyBehavior?
    var linkPreviewsEnabled: Bool?
    var sendTypingIndicators: Bool?
    var sendReadReceipts: Bool?
    var emojiSkinTone: EmojiSkinTone?
    var desktopNotifications: Bool?
    var soundNotifications: Bool?
    var dndEnabled: Bool?
    var dndStartTime: String?
    var dndEndTime: String?
    var showOnlineStatus: Bool?
    var showReadReceipts: Bool?
    var showTypingIndicator: Bool?
    var reduceMotion: Bool?
    var highContrast: Bool?
    var createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case bio
        case onlineStatusPreference = "online_status_preference"
        case theme
        case uiScale = "ui_scale"
        case fontSize = "font_size"
        case accentColor = "accent_color"
        case messageDensity = "message_density"
        case enterKeyBehavior = "enter_key_behavior"
        case linkPreviewsEnabled = "link_previews_enabled"
        case sendTypingIndicators = "send_typing_indicators"
        case sendReadReceipts = "send_read_receipts"
        case emojiSkinTone = "emoji_skin_tone"
        case desktopNotifications = "desktop_notifications"
        case soundNotifications = "sound_notifications"
        case dndEnabled = "dnd_enabled"
        case dndStartTime = "dnd_start_time"
        case dndEndTime = "dnd_end_time"
        case showOnlineStatus = "show_online_status"
        case showReadReceipts = "show_read_receipts"
        case showTypingIndicator = "show_typing_indicator"
        case reduceMotion = "reduce_motion"
        case highContrast = "high_contrast"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
