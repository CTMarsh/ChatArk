import SwiftUI
import Supabase

struct GroupInfoView: View {
    let conversationId: UUID
    @Environment(\.dismiss) private var dismiss
    @State private var conversation: Conversation?
    @State private var participants: [Profile] = []
    @State private var isLoading = true
    @State private var name = ""
    @State private var description = ""
    @State private var showLeaveConfirmation = false
    @State private var isLeaving = false

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
                                    .background(NauticalTheme.ocean.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }

                // Actions
                Section {
                    Button(role: .destructive) {
                        showLeaveConfirmation = true
                    } label: {
                        if isLeaving {
                            ProgressView()
                        } else {
                            Label("Leave Group", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    }
                    .disabled(isLeaving)
                }
            } else if isLoading {
                ProgressView()
            }
        }
        .navigationTitle("Group Info")
        .confirmationDialog("Leave Group", isPresented: $showLeaveConfirmation) {
            Button("Leave", role: .destructive) {
                Task {
                    isLeaving = true
                    defer { isLeaving = false }
                    guard let userId = SupabaseManager.shared.client.auth.currentUser?.id else { return }
                    do {
                        try await conversationService.removeParticipant(conversationId: conversationId, userId: userId)
                        dismiss()
                    } catch {}
                }
            }
        } message: {
            Text("You will no longer receive messages from this group.")
        }
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

#if DEBUG
#Preview {
    GroupInfoView(conversationId: PreviewData.groupConvId)
}
#endif
