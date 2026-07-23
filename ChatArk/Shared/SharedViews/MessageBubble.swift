import SwiftUI

struct MessageBubble: View {
    let message: Message
    let isFromCurrentUser: Bool
    let senderName: String
    let senderAvatarUrl: String?

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if !isFromCurrentUser {
                AvatarView(url: senderAvatarUrl, name: senderName, size: 32)
            }

            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 2) {
                if !isFromCurrentUser {
                    Text(senderName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if message.isDeleted {
                    deletedContent
                } else {
                    messageContent
                }

                HStack(spacing: 4) {
                    Text(DateFormatting.messageTime(message.createdAt))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)

                    if message.isEdited == true {
                        Text("(edited)")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            if isFromCurrentUser {
                AvatarView(url: senderAvatarUrl, name: senderName, size: 32)
            }
        }
        .frame(maxWidth: .infinity, alignment: isFromCurrentUser ? .trailing : .leading)
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(bubbleAccessibilityLabel)
    }

    private var bubbleAccessibilityLabel: String {
        var parts: [String] = []
        if !isFromCurrentUser { parts.append("From \(senderName)") }
        if message.isDeleted {
            parts.append("Deleted message")
        } else {
            if message.fileUrl != nil { parts.append("Attachment") }
            if !message.content.isEmpty { parts.append(message.content) }
        }
        if message.isEdited == true { parts.append("Edited") }
        parts.append(DateFormatting.messageTime(message.createdAt))
        return parts.joined(separator: ", ")
    }

    @ViewBuilder
    private var messageContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Reply preview
            if message.replyToId != nil {
                HStack(spacing: 4) {
                    Rectangle()
                        .fill(ConstellationTheme.primary)
                        .frame(width: 3)
                    Text("Reply")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 2)
            }

            // File attachment
            if let fileUrl = message.fileUrl {
                FileAttachmentView(
                    fileUrl: fileUrl,
                    fileName: message.fileName,
                    fileSize: message.fileSize,
                    fileType: message.fileType,
                    messageType: message.type ?? .file
                )
            }

            // Text content
            if !message.content.isEmpty {
                Text(message.content)
                    .font(.body)
            }
        }
        .padding(12)
        .background(isFromCurrentUser ? Color.accentColor : Color.gray.opacity(0.15))
        .foregroundStyle(isFromCurrentUser ? .white : .primary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var deletedContent: some View {
        Text("This message was deleted")
            .font(.body)
            .italic()
            .foregroundStyle(.secondary)
            .padding(12)
            .background(Color.gray.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#if DEBUG
#Preview("Own bubble") {
    MessageBubble(
        message: PreviewData.ownTextMessage,
        isFromCurrentUser: true,
        senderName: "Chris Marsh",
        senderAvatarUrl: nil
    )
}

#Preview("Other's bubble") {
    MessageBubble(
        message: PreviewData.otherTextMessage,
        isFromCurrentUser: false,
        senderName: "Alice Johnson",
        senderAvatarUrl: nil
    )
}
#endif
