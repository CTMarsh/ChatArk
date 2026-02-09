import Foundation
import SwiftData

@MainActor
final class CacheManager {
    static let shared = CacheManager()

    let container: ModelContainer
    private let isMemoryOnly: Bool

    private init() {
        let schema = Schema([
            CachedMessage.self,
            CachedConversation.self,
        ])
        let configuration = ModelConfiguration(
            "ChatAppCache",
            schema: schema,
            isStoredInMemoryOnly: false,
            groupContainer: .identifier("group.com.chrismarsh.chatark")
        )

        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
            isMemoryOnly = false
        } catch {
            print("CacheManager: Failed to create persistent container, falling back to in-memory: \(error)")
            let fallback = ModelConfiguration(
                "ChatAppCache",
                schema: schema,
                isStoredInMemoryOnly: true
            )
            // In-memory container should always succeed; if it doesn't, something is fundamentally broken
            container = try! ModelContainer(for: schema, configurations: [fallback])
            isMemoryOnly = true
        }
    }

    var context: ModelContext {
        container.mainContext
    }

    // MARK: - Messages

    func cacheMessages(_ messages: [Message]) {
        for message in messages {
            let cached = CachedMessage.from(message)
            context.insert(cached)
        }
        try? context.save()
    }

    func fetchCachedMessages(conversationId: UUID, limit: Int = 50) -> [Message] {
        let predicate = #Predicate<CachedMessage> { $0.conversationId == conversationId }
        var descriptor = FetchDescriptor<CachedMessage>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit

        let cached = (try? context.fetch(descriptor)) ?? []
        return cached.map { $0.toMessage() }
    }

    // MARK: - Conversations

    func cacheConversation(_ detail: ConversationWithDetails) {
        let cached = CachedConversation(
            conversationId: detail.id,
            type: detail.conversation.type.rawValue,
            name: detail.conversation.name,
            avatarUrl: detail.conversation.avatarUrl,
            updatedAt: detail.conversation.updatedAt ?? .now,
            lastMessageContent: detail.lastMessage?.content,
            lastMessageDate: detail.lastMessage?.createdAt,
            unreadCount: detail.unreadCount
        )
        context.insert(cached)
        try? context.save()
    }

    // MARK: - Cleanup

    func clearAll() {
        try? context.delete(model: CachedMessage.self)
        try? context.delete(model: CachedConversation.self)
    }
}
