import AppIntents
import WidgetKit

struct ConversationCountIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Conversations"
    static let description: IntentDescription = "Configure how many conversations to show"

    @Parameter(title: "Number of conversations", default: 3)
    var conversationCount: Int
}
