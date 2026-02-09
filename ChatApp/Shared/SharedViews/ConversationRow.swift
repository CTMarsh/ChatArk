import SwiftUI

struct ConversationRow: View {
    let detail: ConversationWithDetails
    let currentUserId: UUID?

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
                            .background(.blue)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.vertical, 4)
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
