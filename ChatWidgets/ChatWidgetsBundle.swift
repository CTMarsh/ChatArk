import WidgetKit
import SwiftUI

@main
struct ChatWidgetsBundle: WidgetBundle {
    var body: some Widget {
        RecentConversationsWidget()
        UnreadCountWidget()
        ChatWidgetsControl()
        ChatWidgetsLiveActivity()
    }
}
