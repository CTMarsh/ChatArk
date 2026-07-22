import SwiftUI

struct ConversationRow: View {
    let detail: ConversationWithDetails
    let currentUserId: UUID?
    var onMarkAsRead: (() -> Void)?
    var onMute: (() -> Void)?
    var onPin: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack(alignment: .bottomTrailing) {
                AvatarView(
                    url: detail.conversation.avatarUrl ?? otherParticipant?.avatarUrl,
                    name: displayName,
                    size: 48
                )
                if let status = otherParticipant?.status, detail.conversation.type == .direct {
                    StatusIndicator(status: status, size: 14)
                        .offset(x: 2, y: 2)
                }
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(displayName)
                        .font(.headline)
                        .lineLimit(1)

                    Spacer()

                    Text(DateFormatting.conversationDate(detail.lastMessage?.createdAt ?? detail.conversation.updatedAt))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    if let lastMessage = detail.lastMessage {
                        if lastMessage.isDeleted {
                            Text("Message deleted")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .italic()
                        } else {
                            Text(lastMessage.content)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    } else {
                        Text("No messages yet")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                    }

                    Spacer()

                    if detail.unreadCount > 0 {
                        Text("\(detail.unreadCount)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(ConstellationTheme.primary)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.vertical, 4)
        #if os(macOS) || os(iOS)
        .contextMenu {
            if detail.unreadCount > 0 {
                Button {
                    onMarkAsRead?()
                } label: {
                    Label("Mark as Read", systemImage: "envelope.open")
                }
            }

            Button {
                onMute?()
            } label: {
                Label("Mute", systemImage: "bell.slash")
            }

            Divider()

            Button {
                onPin?()
            } label: {
                Label("Pin", systemImage: "pin")
            }
        }
        #endif
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    private var accessibilityDescription: String {
        var parts = [displayName]
        if let lastMessage = detail.lastMessage {
            parts.append(lastMessage.isDeleted ? "Message deleted" : lastMessage.content)
        } else {
            parts.append("No messages yet")
        }
        if detail.unreadCount > 0 {
            parts.append("\(detail.unreadCount) unread")
        }
        if let status = otherParticipant?.status, detail.conversation.type == .direct {
            parts.append(status.rawValue)
        }
        return parts.joined(separator: ", ")
    }

    private var displayName: String {
        if let name = detail.conversation.name {
            return name
        }
        if let other = otherParticipant {
            return other.displayLabel
        }
        return "Conversation"
    }

    private var otherParticipant: Profile? {
        detail.participants.first { $0.id != currentUserId }
    }
}

#if DEBUG
#Preview("DM with unread") {
    ConversationRow(detail: PreviewData.dmDetail, currentUserId: PreviewData.currentUserId)
        .padding()
}

#Preview("Group") {
    ConversationRow(detail: PreviewData.groupDetail, currentUserId: PreviewData.currentUserId)
        .padding()
}

#Preview("No messages") {
    ConversationRow(detail: PreviewData.emptyDetail, currentUserId: PreviewData.currentUserId)
        .padding()
}
#endif
