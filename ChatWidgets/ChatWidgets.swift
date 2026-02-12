import WidgetKit
import SwiftUI

// MARK: - Recent Conversations Widget

struct RecentConversationsEntry: TimelineEntry {
    let date: Date
    let conversations: [WidgetConversationSummary]
}

struct RecentConversationsProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> RecentConversationsEntry {
        RecentConversationsEntry(date: .now, conversations: [])
    }

    func snapshot(for configuration: ConversationCountIntent, in context: Context) async -> RecentConversationsEntry {
        let conversations = SharedDataReader.conversations()
        let count = configuration.conversationCount
        return RecentConversationsEntry(date: .now, conversations: Array(conversations.prefix(count)))
    }

    func timeline(for configuration: ConversationCountIntent, in context: Context) async -> Timeline<RecentConversationsEntry> {
        let conversations = SharedDataReader.conversations()
        let count = configuration.conversationCount
        let entry = RecentConversationsEntry(date: .now, conversations: Array(conversations.prefix(count)))
        return Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(900)))
    }
}

struct RecentConversationsWidget: Widget {
    let kind = "RecentConversationsWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConversationCountIntent.self, provider: RecentConversationsProvider()) { entry in
            RecentConversationsWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Recent Conversations")
        .description("Shows your recent chat conversations")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

// MARK: - Unread Count Widget

struct WidgetUnreadCountEntry: TimelineEntry {
    let date: Date
    let unreadCount: Int
}

struct WidgetUnreadCountProvider: TimelineProvider {
    func placeholder(in context: Context) -> WidgetUnreadCountEntry {
        WidgetUnreadCountEntry(date: .now, unreadCount: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (WidgetUnreadCountEntry) -> Void) {
        let count = SharedDataReader.totalUnreadCount()
        completion(WidgetUnreadCountEntry(date: .now, unreadCount: count))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetUnreadCountEntry>) -> Void) {
        let count = SharedDataReader.totalUnreadCount()
        let entry = WidgetUnreadCountEntry(date: .now, unreadCount: count)
        let timeline = Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(900)))
        completion(timeline)
    }
}

struct UnreadCountWidget: Widget {
    let kind = "UnreadCountWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WidgetUnreadCountProvider()) { entry in
            UnreadCountWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Unread Messages")
        .description("Shows your total unread message count")
        .supportedFamilies([.systemSmall, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}
