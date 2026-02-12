import SwiftUI

struct MessageRow: View {
    let message: Message
    let isFromCurrentUser: Bool
    let senderName: String
    let senderAvatarUrl: String?
    let reactions: [ReactionGroup]
    let onReaction: (String) -> Void
    let onReply: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onPin: () -> Void

    var body: some View {
        VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
            // Pinned indicator
            if message.isPinned == true {
                Label("Pinned", systemImage: "pin.fill")
                    .font(.caption2)
                    .foregroundStyle(.orange)
                    .padding(.horizontal)
            }

            MessageBubble(
                message: message,
                isFromCurrentUser: isFromCurrentUser,
                senderName: senderName,
                senderAvatarUrl: senderAvatarUrl
            )
            .contextMenu {
                if !message.isDeleted {
                    Button {
                        onReply()
                    } label: {
                        Label("Reply", systemImage: "arrowshape.turn.up.left")
                    }

                    Button {
                        onReaction("👍")
                    } label: {
                        Label("Like", systemImage: "hand.thumbsup")
                    }

                    if isFromCurrentUser {
                        Button {
                            onEdit()
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }

                        Button(role: .destructive) {
                            onDelete()
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }

                    Button {
                        onPin()
                    } label: {
                        Label(
                            message.isPinned == true ? "Unpin" : "Pin",
                            systemImage: message.isPinned == true ? "pin.slash" : "pin"
                        )
                    }
                }
            }

            // Reactions
            if !reactions.isEmpty {
                ReactionBar(reactions: reactions, onTap: onReaction)
                    .padding(.horizontal)
            }
        }
    }
}

#if DEBUG
#Preview("Own message") {
    MessageRow(
        message: PreviewData.ownTextMessage,
        isFromCurrentUser: true,
        senderName: "Chris Marsh",
        senderAvatarUrl: nil,
        reactions: PreviewData.sampleReactions,
        onReaction: { _ in },
        onReply: {},
        onEdit: {},
        onDelete: {},
        onPin: {}
    )
}

#Preview("Other's message") {
    MessageRow(
        message: PreviewData.otherTextMessage,
        isFromCurrentUser: false,
        senderName: "Alice Johnson",
        senderAvatarUrl: nil,
        reactions: [],
        onReaction: { _ in },
        onReply: {},
        onEdit: {},
        onDelete: {},
        onPin: {}
    )
}
#endif
