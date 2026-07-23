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
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

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
                        .background(ConstellationTheme.primary)
                        .clipShape(Capsule())
                }
            }
            .padding()
            .activityBackgroundTint(.clear)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded
                DynamicIslandExpandedRegion(.leading) {
                    Image("AppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
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
                    .foregroundStyle(ConstellationTheme.primary)
            } compactTrailing: {
                if context.state.unreadCount > 0 {
                    Text("\(context.state.unreadCount)")
                        .font(.caption)
                        .fontWeight(.bold)
                }
            } minimal: {
                Image(systemName: "bubble.left.fill")
                    .foregroundStyle(ConstellationTheme.primary)
            }
        }
    }
}
#endif
