import SwiftUI
import Supabase

struct GroupInfoView: View {
    let conversationId: UUID
    @Environment(\.dismiss) private var dismiss
    @State private var conversation: Conversation?
    @State private var participants: [ConversationParticipant] = []
    @State private var profiles: [UUID: Profile] = [:]
    @State private var isLoading = true
    @State private var error: String?
    @State private var showLeaveConfirmation = false
    @State private var isLeaving = false
    @State private var isEditingName = false
    @State private var editedName = ""
    @State private var isEditingDescription = false
    @State private var editedDescription = ""
    @State private var showAddMember = false
    @State private var removingMember: ConversationParticipant?
    @State private var showRemoveConfirm = false

    private let conversationService = ConversationService()

    private var currentUserId: UUID? {
        SupabaseManager.shared.client.auth.currentUser?.id
    }

    private var isCurrentUserAdmin: Bool {
        guard let uid = currentUserId else { return false }
        return participants.contains { $0.userId == uid && $0.role == "admin" }
            || conversation?.createdBy == uid
    }

    var body: some View {
        List {
            if let conversation {
                infoSection(conversation)
                membersSection(conversation)
                actionsSection
            } else if isLoading {
                ProgressView()
            }
        }
        .navigationTitle("Group Info")
        .confirmationDialog("Leave Group", isPresented: $showLeaveConfirmation) {
            Button("Leave", role: .destructive) {
                Task { await leaveGroup() }
            }
        } message: {
            Text("You will no longer receive messages from this group.")
        }
        .confirmationDialog("Remove Member", isPresented: $showRemoveConfirm) {
            Button("Remove", role: .destructive) {
                if let member = removingMember {
                    Task { await removeMember(member) }
                }
            }
        } message: {
            if let member = removingMember, let profile = profiles[member.userId] {
                Text("Remove \(profile.displayLabel) from this group?")
            } else {
                Text("Remove this member from the group?")
            }
        }
        .sheet(isPresented: $showAddMember) {
            AddGroupMemberSheet(
                conversationId: conversationId,
                existingParticipantIds: Set(participants.map(\.userId)),
                onAdded: { reload() }
            )
        }
        .task { await loadData() }
    }

    // MARK: - Info Section

    @ViewBuilder
    private func infoSection(_ conversation: Conversation) -> some View {
        Section {
            HStack {
                AvatarView(
                    url: conversation.avatarUrl,
                    name: conversation.name ?? "Group",
                    size: 64
                )

                VStack(alignment: .leading) {
                    if isEditingName {
                        HStack {
                            TextField("Group Name", text: $editedName)
                            Button("Save") {
                                Task { await saveName() }
                            }
                            .buttonStyle(.borderless)
                            Button("Cancel") {
                                editedName = conversation.name ?? ""
                                isEditingName = false
                            }
                            .buttonStyle(.borderless)
                            .foregroundStyle(.secondary)
                        }
                    } else {
                        HStack {
                            Text(conversation.name ?? "Group Chat")
                                .arkType(.lead)
                                .fontWeight(.bold)
                            if isCurrentUserAdmin {
                                Button {
                                    editedName = conversation.name ?? ""
                                    isEditingName = true
                                } label: {
                                    Image(systemName: "pencil")
                                        .arkType(.cap)
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                    }

                    if isEditingDescription {
                        HStack {
                            TextField("Description", text: $editedDescription)
                            Button("Save") {
                                Task { await saveDescription() }
                            }
                            .buttonStyle(.borderless)
                            Button("Cancel") {
                                editedDescription = conversation.description ?? ""
                                isEditingDescription = false
                            }
                            .buttonStyle(.borderless)
                            .foregroundStyle(.secondary)
                        }
                    } else {
                        HStack {
                            if let desc = conversation.description, !desc.isEmpty {
                                Text(desc)
                                    .arkType(.body)
                                    .foregroundStyle(.secondary)
                            } else if isCurrentUserAdmin {
                                Text("Add a description")
                                    .arkType(.body)
                                    .foregroundStyle(.tertiary)
                            }
                            if isCurrentUserAdmin {
                                Button {
                                    editedDescription = conversation.description ?? ""
                                    isEditingDescription = true
                                } label: {
                                    Image(systemName: "pencil")
                                        .arkType(.cap)
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                    }

                    Text("\(participants.count) members")
                        .arkType(.cap)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, ConstellationSpacing.s1)
        }

        if let error {
            Section {
                Text(error)
                    .foregroundStyle(.red)
                    .arkType(.cap)
            }
        }
    }

    // MARK: - Members Section

    @ViewBuilder
    private func membersSection(_ conversation: Conversation) -> some View {
        Section {
            ForEach(participants) { participant in
                memberRow(participant, conversation: conversation)
            }
        } header: {
            HStack {
                Text("Members (\(participants.count))")
                Spacer()
                if isCurrentUserAdmin {
                    Button {
                        showAddMember = true
                    } label: {
                        Label("Add", systemImage: "plus")
                            .arkType(.cap)
                    }
                }
            }
        }
    }

    private func memberRow(_ participant: ConversationParticipant, conversation: Conversation) -> some View {
        let profile = profiles[participant.userId]
        let isCreator = participant.userId == conversation.createdBy
        let role = participant.role ?? "member"
        let isSelf = participant.userId == currentUserId

        return HStack(spacing: ConstellationSpacing.gapInline) {
            ZStack(alignment: .bottomTrailing) {
                AvatarView(url: profile?.avatarUrl, name: profile?.displayLabel ?? "User", size: 36)
                if let status = profile?.status {
                    StatusIndicator(status: status, size: 10)
                }
            }

            VStack(alignment: .leading) {
                HStack(spacing: ConstellationSpacing.s1) {
                    Text(profile?.displayLabel ?? "User")
                        .arkType(.body)
                    if isSelf {
                        Text("(you)")
                            .arkType(.cap)
                            .foregroundStyle(.secondary)
                    }
                }
                if let username = profile?.username {
                    Text("@\(username)")
                        .arkType(.cap)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Role badge / picker
            if isCurrentUserAdmin && !isCreator && !isSelf {
                Picker("Role", selection: Binding(
                    get: { role },
                    set: { newRole in
                        Task { await changeRole(participant, newRole: newRole) }
                    }
                )) {
                    Text("Admin").tag("admin")
                    Text("Moderator").tag("moderator")
                    Text("Member").tag("member")
                }
                .labelsHidden()
                .frame(width: 110)

                // Remove button
                Button(role: .destructive) {
                    removingMember = participant
                    showRemoveConfirm = true
                } label: {
                    Image(systemName: "person.badge.minus")
                        .foregroundStyle(.red)
                }
                .buttonStyle(.borderless)
            } else {
                Text(isCreator ? "Creator" : role.capitalized)
                    .arkType(.cap)
                    .padding(.horizontal, ConstellationSpacing.s1)
                    .padding(.vertical, ConstellationSpacing.s1)
                    .background(isCreator ? ConstellationTheme.amber.opacity(0.15) : ConstellationTheme.primary.opacity(0.1))
                    .foregroundStyle(isCreator ? ConstellationTheme.amber : ConstellationTheme.primary)
                    .clipShape(Capsule())
            }
        }
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
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
    }

    // MARK: - Data Operations

    private func loadData() async {
        do {
            conversation = try await conversationService.fetchConversation(id: conversationId)
            participants = try await conversationService.fetchParticipants(conversationId: conversationId)
            let profileList = try await conversationService.fetchParticipantProfiles(conversationId: conversationId)
            profiles = Dictionary(uniqueKeysWithValues: profileList.map { ($0.id, $0) })
            isLoading = false
        } catch {
            isLoading = false
        }
    }

    private func reload() {
        Task { await loadData() }
    }

    private func saveName() async {
        let trimmed = String(editedName.prefix(100)).trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        do {
            try await conversationService.updateConversation(id: conversationId, name: trimmed)
            conversation?.name = trimmed
            isEditingName = false
            error = nil
        } catch {
            self.error = ErrorSanitizer.sanitize(error)
        }
    }

    private func saveDescription() async {
        let trimmed = String(editedDescription.prefix(500))
        do {
            try await conversationService.updateConversation(id: conversationId, description: trimmed)
            conversation?.description = trimmed.isEmpty ? nil : trimmed
            isEditingDescription = false
            error = nil
        } catch {
            self.error = ErrorSanitizer.sanitize(error)
        }
    }

    private func changeRole(_ participant: ConversationParticipant, newRole: String) async {
        guard let role = ParticipantRole(rawValue: newRole) else { return }
        do {
            try await conversationService.updateParticipantRole(
                conversationId: conversationId,
                userId: participant.userId,
                role: role
            )
            if let idx = participants.firstIndex(where: { $0.id == participant.id }) {
                participants[idx] = ConversationParticipant(
                    id: participant.id,
                    conversationId: participant.conversationId,
                    userId: participant.userId,
                    role: newRole,
                    joinedAt: participant.joinedAt,
                    lastReadAt: participant.lastReadAt,
                    notificationsEnabled: participant.notificationsEnabled
                )
            }
            error = nil
        } catch {
            self.error = ErrorSanitizer.sanitize(error)
        }
    }

    private func removeMember(_ participant: ConversationParticipant) async {
        do {
            try await conversationService.removeParticipant(
                conversationId: conversationId,
                userId: participant.userId
            )
            participants.removeAll { $0.id == participant.id }
            profiles.removeValue(forKey: participant.userId)
            removingMember = nil
            error = nil
        } catch {
            self.error = ErrorSanitizer.sanitize(error)
        }
    }

    private func leaveGroup() async {
        isLeaving = true
        defer { isLeaving = false }
        guard let userId = currentUserId else { return }
        do {
            try await conversationService.removeParticipant(conversationId: conversationId, userId: userId)
            dismiss()
        } catch {}
    }
}

// MARK: - Add Group Member Sheet

struct AddGroupMemberSheet: View {
    let conversationId: UUID
    let existingParticipantIds: Set<UUID>
    let onAdded: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var isAdding = false
    @State private var error: String?

    private let conversationService = ConversationService()

    var body: some View {
        NavigationStack {
            UserSearchView { profile in
                guard !existingParticipantIds.contains(profile.id) else {
                    error = "\(profile.displayLabel) is already a member"
                    return
                }
                Task { await addMember(profile) }
            }
            .navigationTitle("Add Member")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .overlay {
                if isAdding {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(.ultraThinMaterial)
                }
            }
            .alert("Error", isPresented: Binding(
                get: { error != nil },
                set: { if !$0 { error = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                if let error { Text(error) }
            }
        }
    }

    private func addMember(_ profile: Profile) async {
        isAdding = true
        defer { isAdding = false }
        do {
            try await conversationService.addParticipant(conversationId: conversationId, userId: profile.id)
            onAdded()
            dismiss()
        } catch {
            self.error = ErrorSanitizer.sanitize(error)
        }
    }
}

#if DEBUG
#Preview {
    GroupInfoView(conversationId: PreviewData.groupConvId)
}
#endif
