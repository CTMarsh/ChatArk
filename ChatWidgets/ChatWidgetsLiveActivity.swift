import ActivityKit
import WidgetKit
import SwiftUI

// This must match ChatActivityAttributes in iOS/LiveActivity/ChatLiveActivity.swift exactly
struct ChatWidgetsAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var lastMessageSender: String
        var lastMessageContent: String
        var unreadCount: Int
        var timestamp: Date
    }

    var conversationName: String
    var conversationId: String
}

struct ChatWidgetsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ChatWidgetsAttributes.self) { context in
            lockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    initialsView(for: context.attributes.conversationName)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.unreadCount > 0 {
                        unreadBadge(count: context.state.unreadCount)
                    }
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.conversationName)
                        .font(.headline)
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("\(context.state.lastMessageSender): \(context.state.lastMessageContent)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            } compactLeading: {
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            } compactTrailing: {
                if context.state.unreadCount > 0 {
                    Text("\(context.state.unreadCount)")
                        .font(.caption)
                        .fontWeight(.bold)
                }
            } minimal: {
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            }
            .widgetURL(URL(string: "chatark://conversation/\(context.attributes.conversationId)"))
        }
    }

    private func lockScreenView(context: ActivityViewContext<ChatWidgetsAttributes>) -> some View {
        HStack(spacing: 12) {
            initialsView(for: context.attributes.conversationName)

            VStack(alignment: .leading, spacing: 2) {
                Text(context.attributes.conversationName)
                    .font(.headline)
                    .lineLimit(1)
                Text("\(context.state.lastMessageSender): \(context.state.lastMessageContent)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if context.state.unreadCount > 0 {
                    unreadBadge(count: context.state.unreadCount)
                }
                Text(context.state.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .activityBackgroundTint(.clear)
        .widgetURL(URL(string: "chatark://conversation/\(context.attributes.conversationId)"))
    }

    private func initialsView(for name: String) -> some View {
        let initials = name.split(separator: " ")
            .prefix(2)
            .compactMap(\.first)
            .map(String.init)
            .joined()

        return Text(initials.isEmpty ? "?" : initials)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .frame(width: 32, height: 32)
            .background(Color(widgetHex: "4A8BC2"))
            .clipShape(Circle())
    }

    private func unreadBadge(count: Int) -> some View {
        Text("\(count)")
            .font(.caption)
            .fontWeight(.bold)
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(Color(widgetHex: "4A8BC2"))
            .clipShape(Capsule())
    }
}

#if DEBUG
#Preview("Live Activity", as: .content, using: ChatWidgetsAttributes(conversationName: "Team Chat", conversationId: "preview-123")) {
    ChatWidgetsLiveActivity()
} contentStates: {
    ChatWidgetsAttributes.ContentState(
        lastMessageSender: "Alice",
        lastMessageContent: "The build is passing now!",
        unreadCount: 3,
        timestamp: .now
    )
}
#endif
