import AppIntents
import WidgetKit

// MARK: - Conversation Entity

struct ConversationEntity: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Conversation")
    static var defaultQuery = ConversationEntityQuery()

    var id: String
    var name: String
    var unreadCount: Int

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

// MARK: - Conversation Entity Query

struct ConversationEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [ConversationEntity] {
        SharedDataReader.conversations()
            .filter { identifiers.contains($0.id) }
            .map { ConversationEntity(id: $0.id, name: $0.name, unreadCount: $0.unreadCount) }
    }

    func suggestedEntities() async throws -> [ConversationEntity] {
        SharedDataReader.conversations()
            .prefix(10)
            .map { ConversationEntity(id: $0.id, name: $0.name, unreadCount: $0.unreadCount) }
    }
}

// MARK: - Select Conversation Intent

struct SelectConversationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Select Conversation"
    static var description: IntentDescription = "Choose a conversation to display"

    @Parameter(title: "Conversation")
    var conversation: ConversationEntity?
}

// MARK: - Open ChatArk Intent

struct OpenChatArkIntent: AppIntent {
    static var title: LocalizedStringResource = "Open ChatArk"
    static var description: IntentDescription = "Opens the ChatArk app"
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        .result()
    }
}
