import WidgetKit
import SwiftUI

// MARK: - Recent Conversations Widget

struct RecentConversationsEntry: TimelineEntry {
    let date: Date
    let conversations: [WidgetConversationSummary]
}

struct RecentConversationsProvider: TimelineProvider {
    func placeholder(in context: Context) -> RecentConversationsEntry {
        RecentConversationsEntry(date: .now, conversations: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (RecentConversationsEntry) -> Void) {
        let conversations = SharedDataReader.conversations()
        completion(RecentConversationsEntry(date: .now, conversations: Array(conversations.prefix(5))))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RecentConversationsEntry>) -> Void) {
        let conversations = SharedDataReader.conversations()
        let entry = RecentConversationsEntry(date: .now, conversations: Array(conversations.prefix(5)))
        let timeline = Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(900)))
        completion(timeline)
    }
}

struct RecentConversationsWidget: Widget {
    let kind = "RecentConversationsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RecentConversationsProvider()) { entry in
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
