import SwiftUI

struct GroupInfoView: View {
    let conversationId: UUID
    @State private var conversation: Conversation?
    @State private var participants: [Profile] = []
    @State private var isLoading = true
    @State private var name = ""
    @State private var description = ""

    private let conversationService = ConversationService()

    var body: some View {
        List {
            if let conversation {
                // Group info
                Section {
                    HStack {
                        AvatarView(
                            url: conversation.avatarUrl,
                            name: conversation.name ?? "Group",
                            size: 64
                        )

                        VStack(alignment: .leading) {
                            Text(conversation.name ?? "Group Chat")
                                .font(.title2)
                                .fontWeight(.bold)

                            if let desc = conversation.description {
                                Text(desc)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            Text("\(participants.count) members")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                // Members
                Section("Members") {
                    ForEach(participants) { profile in
                        HStack(spacing: 12) {
                            ZStack(alignment: .bottomTrailing) {
                                AvatarView(url: profile.avatarUrl, name: profile.displayLabel, size: 36)
                                if let status = profile.status {
                                    StatusIndicator(status: status, size: 10)
                                }
                            }

                            VStack(alignment: .leading) {
                                Text(profile.displayLabel)
                                    .font(.body)
                                if let username = profile.username {
                                    Text("@\(username)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()

                            if profile.id == conversation.createdBy {
                                Text("Admin")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }

                // Actions
                Section {
                    Button(role: .destructive) {
                        // Leave group
                    } label: {
                        Label("Leave Group", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            } else if isLoading {
                ProgressView()
            }
        }
        .navigationTitle("Group Info")
        .task {
            do {
                conversation = try await conversationService.fetchConversation(id: conversationId)
                participants = try await conversationService.fetchParticipantProfiles(conversationId: conversationId)
                isLoading = false
            } catch {
                isLoading = false
            }
        }
    }
}
