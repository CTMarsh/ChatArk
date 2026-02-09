import SwiftUI

struct ConversationWindowGroup: View {
    let conversationId: UUID
    let title: String

    var body: some View {
        ChatView(conversationId: conversationId, title: title)
    }
}
