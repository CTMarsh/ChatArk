#if os(iOS)
import ActivityKit
import WidgetKit
import SwiftUI

struct ChatActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var lastMessageSender: String
        var lastMessageContent: String
        var unreadCount: Int
        var timestamp: Date
    }

    var conversationName: String
    var conversationId: String
}

struct ChatLiveActivityView: Widget {
    let kind = "ChatLiveActivity"

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ChatActivityAttributes.self) { context in
            // Lock screen / banner
            HStack(spacing: 12) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)

                VStack(alignment: .leading, spacing: 2) {
                    Text(context.attributes.conversationName)
                        .font(.headline)

                    Text("\(context.state.lastMessageSender): \(context.state.lastMessageContent)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                if context.state.unreadCount > 0 {
                    Text("\(context.state.unreadCount)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.blue)
                        .clipShape(Capsule())
                }
            }
            .padding()
            .activityBackgroundTint(.clear)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .foregroundStyle(.blue)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.unreadCount > 0 {
                        Text("\(context.state.unreadCount)")
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.conversationName)
                        .font(.headline)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.lastMessageContent)
                        .font(.caption)
                        .lineLimit(2)
                }
            } compactLeading: {
                Image(systemName: "bubble.left.fill")
                    .foregroundStyle(.blue)
            } compactTrailing: {
                if context.state.unreadCount > 0 {
                    Text("\(context.state.unreadCount)")
                        .font(.caption)
                        .fontWeight(.bold)
                }
            } minimal: {
                Image(systemName: "bubble.left.fill")
                    .foregroundStyle(.blue)
            }
        }
    }
}
#endif
