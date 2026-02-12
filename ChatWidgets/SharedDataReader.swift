import Foundation
import SwiftUI

// MARK: - Widget-local types (mirrors SharedConversationSummary from main app)

struct WidgetConversationSummary: Codable, Identifiable {
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

// MARK: - SharedDataReader

enum SharedDataReader {
    private static let suiteName = "group.com.chrismarsh.chatark"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    static func conversations() -> [WidgetConversationSummary] {
        guard let encrypted = defaults?.data(forKey: "recent_conversations"),
              let data = WidgetDecryption.decrypt(encrypted),
              let items = try? decoder.decode([WidgetConversationSummary].self, from: data) else {
            // Fallback: try reading unencrypted (migration period)
            if let rawData = defaults?.data(forKey: "recent_conversations"),
               let items = try? decoder.decode([WidgetConversationSummary].self, from: rawData) {
                return items
            }
            return []
        }
        return items
    }

    static func totalUnreadCount() -> Int {
        defaults?.integer(forKey: "total_unread_count") ?? 0
    }

    static func currentUserName() -> String? {
        if let encrypted = defaults?.data(forKey: "current_user_name") {
            return WidgetDecryption.decryptString(encrypted)
        }
        // Fallback: try reading unencrypted (migration period)
        return defaults?.string(forKey: "current_user_name")
    }

    static func accentColorHex() -> String {
        defaults?.string(forKey: "accent_color") ?? "#4A8BC2"
    }
}

// MARK: - Color(hex:) extension (can't import from main app)

extension Color {
    init(widgetHex hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let scanner = Scanner(string: hex)
        var color: UInt64 = 0
        scanner.scanHexInt64(&color)

        let r = Double((color >> 16) & 0xFF) / 255.0
        let g = Double((color >> 8) & 0xFF) / 255.0
        let b = Double(color & 0xFF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}
