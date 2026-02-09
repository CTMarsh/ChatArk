import AppIntents
import SwiftUI
import WidgetKit

struct ChatWidgetsControl: ControlWidget {
    static let kind = "com.chrismarsh.chatark.OpenControl"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind) {
            ControlWidgetButton(action: OpenChatArkIntent()) {
                Label("ChatArk", systemImage: "bubble.left.and.bubble.right.fill")
            }
        }
        .displayName("Open ChatArk")
        .description("Quickly open the ChatArk app")
    }
}
