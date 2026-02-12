#if DEBUG
import Foundation

// MARK: - Preview UUIDs (deterministic for consistent previews)

enum PreviewData {
    static let currentUserId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    static let aliceId = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
    static let bobId = UUID(uuidString: "00000000-0000-0000-0000-000000000003")!
    static let carolId = UUID(uuidString: "00000000-0000-0000-0000-000000000004")!
    static let dmConvId = UUID(uuidString: "00000000-0000-0000-0000-000000000010")!
    static let groupConvId = UUID(uuidString: "00000000-0000-0000-0000-000000000011")!
    static let emptyConvId = UUID(uuidString: "00000000-0000-0000-0000-000000000012")!
    static let msg1Id = UUID(uuidString: "00000000-0000-0000-0000-000000000020")!
    static let msg2Id = UUID(uuidString: "00000000-0000-0000-0000-000000000021")!
    static let msg3Id = UUID(uuidString: "00000000-0000-0000-0000-000000000022")!
    static let msg4Id = UUID(uuidString: "00000000-0000-0000-0000-000000000023")!
    static let msg5Id = UUID(uuidString: "00000000-0000-0000-0000-000000000024")!

    // MARK: - Profiles

    static let alice = Profile(
        id: aliceId,
        username: "alice",
        displayName: "Alice Johnson",
        avatarUrl: nil,
        status: .online,
        lastSeenAt: .now,
        createdAt: .now,
        email: "alice@example.com"
    )

    static let bob = Profile(
        id: bobId,
        username: "bob",
        displayName: "Bob Smith",
        avatarUrl: nil,
        status: .away,
        lastSeenAt: Date(timeIntervalSinceNow: -300),
        createdAt: .now,
        email: "bob@example.com"
    )

    static let carol = Profile(
        id: carolId,
        username: "carol",
        displayName: "Carol Williams",
        avatarUrl: nil,
        status: .dnd,
        lastSeenAt: Date(timeIntervalSinceNow: -600),
        createdAt: .now,
        email: "carol@example.com"
    )

    static let currentUser = Profile(
        id: currentUserId,
        username: "chris",
        displayName: "Chris Marsh",
        avatarUrl: nil,
        status: .online,
        lastSeenAt: .now,
        createdAt: .now,
        email: "chris@example.com"
    )

    // MARK: - Conversations

    static let dmConversation = Conversation(
        id: dmConvId,
        type: .direct,
        name: nil,
        createdBy: currentUserId,
        createdAt: .now,
        updatedAt: .now
    )

    static let groupConversation = Conversation(
        id: groupConvId,
        type: .group,
        name: "Team Chat",
        createdBy: currentUserId,
        createdAt: .now,
        updatedAt: .now
    )

    static let emptyConversation = Conversation(
        id: emptyConvId,
        type: .direct,
        name: nil,
        createdBy: currentUserId,
        createdAt: .now,
        updatedAt: .now
    )

    // MARK: - Messages

    static let ownTextMessage = Message(
        id: msg1Id,
        conversationId: dmConvId,
        senderId: currentUserId,
        content: "Hey, how are you doing?",
        type: .text,
        createdAt: .now
    )

    static let otherTextMessage = Message(
        id: msg2Id,
        conversationId: dmConvId,
        senderId: aliceId,
        content: "I'm great! Working on the new feature. Should be ready by tomorrow.",
        type: .text,
        createdAt: Date(timeIntervalSinceNow: -60)
    )

    static let deletedMessage = Message(
        id: msg3Id,
        conversationId: dmConvId,
        senderId: bobId,
        content: "This was deleted",
        type: .text,
        createdAt: Date(timeIntervalSinceNow: -120),
        deletedAt: .now,
        deletedBy: bobId
    )

    static let editedMessage = Message(
        id: msg4Id,
        conversationId: dmConvId,
        senderId: aliceId,
        content: "Actually, it might be ready tonight (edited)",
        type: .text,
        isEdited: true,
        createdAt: Date(timeIntervalSinceNow: -30),
        updatedAt: .now
    )

    static let pinnedMessage = Message(
        id: msg5Id,
        conversationId: groupConvId,
        senderId: aliceId,
        content: "Sprint planning is at 10am every Monday",
        type: .text,
        createdAt: Date(timeIntervalSinceNow: -3600),
        isPinned: true,
        pinnedAt: .now,
        pinnedBy: currentUserId
    )

    static let imageMessage = Message(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000025")!,
        conversationId: dmConvId,
        senderId: aliceId,
        content: "",
        type: .image,
        createdAt: Date(timeIntervalSinceNow: -180),
        fileUrl: "https://example.com/photo.jpg",
        fileName: "photo.jpg",
        fileSize: 245_000,
        fileType: "image/jpeg"
    )

    static let fileMessage = Message(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000026")!,
        conversationId: dmConvId,
        senderId: bobId,
        content: "Here's the document",
        type: .file,
        createdAt: Date(timeIntervalSinceNow: -240),
        fileUrl: "https://example.com/report.pdf",
        fileName: "Q4 Report.pdf",
        fileSize: 1_500_000,
        fileType: "application/pdf"
    )

    static let linkMessage = Message(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000027")!,
        conversationId: dmConvId,
        senderId: aliceId,
        content: "Check this out: https://example.com",
        type: .text,
        createdAt: Date(timeIntervalSinceNow: -300),
        linkPreviews: [sampleLinkPreview]
    )

    // MARK: - Link Preview

    static let sampleLinkPreview = LinkPreview(
        url: "https://example.com/article",
        title: "Interesting Article",
        description: "A fascinating read about modern technology and its impact.",
        imageUrl: nil
    )

    // MARK: - Reactions

    static let thumbsUpReaction = ReactionGroup(
        emoji: "👍",
        count: 3,
        userIds: [aliceId, bobId, carolId],
        currentUserReacted: false
    )

    static let heartReaction = ReactionGroup(
        emoji: "❤️",
        count: 1,
        userIds: [currentUserId],
        currentUserReacted: true
    )

    static let sampleReactions = [thumbsUpReaction, heartReaction]

    // MARK: - Conversation With Details

    static let dmDetail = ConversationWithDetails(
        conversation: dmConversation,
        lastMessage: otherTextMessage,
        unreadCount: 3,
        participants: [currentUser, alice]
    )

    static let groupDetail = ConversationWithDetails(
        conversation: groupConversation,
        lastMessage: pinnedMessage,
        unreadCount: 0,
        participants: [currentUser, alice, bob, carol]
    )

    static let emptyDetail = ConversationWithDetails(
        conversation: emptyConversation,
        lastMessage: nil,
        unreadCount: 0,
        participants: [currentUser, bob]
    )
}
#endif
