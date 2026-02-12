import AppIntents
import WidgetKit

struct ConversationCountIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Conversations"
    static var description: IntentDescription = "Configure how many conversations to show"

    @Parameter(title: "Number of conversations", default: 3)
    var conversationCount: Int
}
