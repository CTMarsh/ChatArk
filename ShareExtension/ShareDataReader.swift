import Foundation

// MARK: - Share Extension local types

struct ShareConversationSummary: Codable, Identifiable {
    let id: String
    let name: String
    let avatarUrl: String?
    let participantNames: [String]
    let type: String
}

struct SharePendingItem: Codable {
    enum ItemType: String, Codable {
        case text
        case url
        case image
        case file
    }

    let type: ItemType
    let text: String?
    let fileName: String?
}

struct SharePendingData: Codable {
    let id: String
    let conversationId: String
    let conversationName: String
    let items: [SharePendingItem]
    let createdAt: Date
}

// MARK: - ShareDataReader

enum ShareDataReader {
    private static let suiteName = "group.com.chrismarsh.chatark"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    static func conversations() -> [ShareConversationSummary] {
        guard let data = defaults?.data(forKey: "recent_conversations"),
              let items = try? decoder.decode([ShareConversationSummary].self, from: data) else {
            return []
        }
        return items
    }

    static func currentUserName() -> String? {
        defaults?.string(forKey: "current_user_name")
    }

    // MARK: - Write pending share

    static func writePendingShare(_ share: SharePendingData) {
        guard let data = try? encoder.encode(share) else { return }
        defaults?.set(data, forKey: "pending_share")
    }

    static func pendingSharesDirectory() -> URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: suiteName)?
            .appendingPathComponent("PendingShares", isDirectory: true)
    }

    static func saveFile(data: Data, fileName: String, shareId: String) -> URL? {
        guard let dir = pendingSharesDirectory() else { return nil }
        let shareDir = dir.appendingPathComponent(shareId, isDirectory: true)
        try? FileManager.default.createDirectory(at: shareDir, withIntermediateDirectories: true)
        let fileUrl = shareDir.appendingPathComponent(fileName)
        do {
            try data.write(to: fileUrl)
            return fileUrl
        } catch {
            return nil
        }
    }
}
