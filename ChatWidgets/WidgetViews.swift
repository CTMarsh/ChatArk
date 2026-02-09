import SwiftUI
import WidgetKit

// MARK: - Recent Conversations Widget View

struct RecentConversationsWidgetView: View {
    let entry: RecentConversationsEntry

    var body: some View {
        if entry.conversations.isEmpty {
            emptyState
        } else {
            conversationList
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.title)
                .foregroundStyle(.secondary)
            Text("No Conversations")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("Open ChatArk to get started")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }

    private var conversationList: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerRow
            ForEach(entry.conversations) { conversation in
                Link(destination: URL(string: "chatark://conversation/\(conversation.id)")!) {
                    WidgetConversationRow(conversation: conversation)
                }
                if conversation.id != entry.conversations.last?.id {
                    Divider().padding(.leading, 40)
                }
            }
        }
    }

    private var headerRow: some View {
        HStack {
            Text("ChatArk")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            Spacer()
            let total = entry.conversations.reduce(0) { $0 + $1.unreadCount }
            if total > 0 {
                Text("\(total) unread")
                    .font(.caption2)
                    .foregroundStyle(Color(widgetHex: SharedDataReader.accentColorHex()))
            }
        }
        .padding(.bottom, 4)
    }
}

// MARK: - Conversation Row

struct WidgetConversationRow: View {
    let conversation: WidgetConversationSummary

    var body: some View {
        HStack(spacing: 8) {
            initialsAvatar
            VStack(alignment: .leading, spacing: 1) {
                HStack {
                    Text(conversation.name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    Spacer()
                    if let date = conversation.lastMessageDate {
                        Text(date, style: .relative)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                if let content = conversation.lastMessageContent {
                    Text(content)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            if conversation.unreadCount > 0 {
                Text("\(conversation.unreadCount)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color(widgetHex: SharedDataReader.accentColorHex()))
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 4)
    }

    private var initialsAvatar: some View {
        let initials = conversation.name.split(separator: " ")
            .prefix(2)
            .compactMap(\.first)
            .map(String.init)
            .joined()

        return Text(initials.isEmpty ? "?" : initials)
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(.white)
            .frame(width: 28, height: 28)
            .background(Color(widgetHex: SharedDataReader.accentColorHex()).opacity(0.8))
            .clipShape(Circle())
    }
}

// MARK: - Unread Count Widget View

struct UnreadCountWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: WidgetUnreadCountEntry

    var body: some View {
        switch family {
        case .systemSmall:
            smallView
        case .accessoryCircular:
            circularView
        case .accessoryRectangular:
            rectangularView
        case .accessoryInline:
            inlineView
        default:
            smallView
        }
    }

    private var smallView: some View {
        VStack(spacing: 8) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.title)
                .foregroundStyle(Color(widgetHex: SharedDataReader.accentColorHex()))
            Text("\(entry.unreadCount)")
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.5)
            Text(entry.unreadCount == 1 ? "unread" : "unread")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var circularView: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 1) {
                Image(systemName: "bubble.left.fill")
                    .font(.caption2)
                Text("\(entry.unreadCount)")
                    .font(.headline)
                    .fontWeight(.bold)
            }
        }
    }

    private var rectangularView: some View {
        HStack(spacing: 8) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.title3)
            VStack(alignment: .leading, spacing: 1) {
                Text("ChatArk")
                    .font(.caption)
                    .fontWeight(.semibold)
                Text("\(entry.unreadCount) unread")
                    .font(.caption2)
            }
        }
    }

    private var inlineView: some View {
        Label("\(entry.unreadCount) unread messages", systemImage: "bubble.left.fill")
    }
}
