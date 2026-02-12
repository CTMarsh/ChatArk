import SwiftUI

struct ConversationWindowGroup: View {
    let conversationId: UUID
    let title: String

    var body: some View {
        ChatView(conversationId: conversationId, title: title)
    }
}

extension EnvironmentValues {
    @Entry var openConversationWindow: (UUID, String) -> Void = { _, _ in }
}

#if DEBUG
#Preview {
    ConversationWindowGroup(conversationId: PreviewData.dmConvId, title: "Alice Johnson")
}
#endif
