#if os(iOS)
import WidgetKit
import SwiftUI

struct UnreadCountWidget: Widget {
    let kind = "UnreadCountWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ChatWidgetProvider()) { entry in
            UnreadCountWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Unread Messages")
        .description("Shows your total unread message count")
        .supportedFamilies([.systemSmall, .accessoryCircular, .accessoryRectangular])
    }
}

struct ChatWidgetEntry: TimelineEntry {
    let date: Date
    let unreadCount: Int
    let recentConversations: [(name: String, lastMessage: String)]
}

struct ChatWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> ChatWidgetEntry {
        ChatWidgetEntry(
            date: .now,
            unreadCount: 3,
            recentConversations: [
                (name: "Alice", lastMessage: "Hey there!"),
                (name: "Team Chat", lastMessage: "Meeting at 2pm"),
            ]
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (ChatWidgetEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ChatWidgetEntry>) -> Void) {
        let entry = ChatWidgetEntry(
            date: .now,
            unreadCount: 0,
            recentConversations: []
        )
        let timeline = Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(900)))
        completion(timeline)
    }
}

struct UnreadCountWidgetView: View {
    let entry: ChatWidgetEntry

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.title)
                .foregroundStyle(.blue)

            Text("\(entry.unreadCount)")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Unread")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
#endif
