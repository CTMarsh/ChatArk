import SwiftUI

struct NewConversationView: View {
    let onCreated: (UUID) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var searchQuery = ""
    @State private var searchResults: [Profile] = []
    @State private var selectedUsers: [Profile] = []
    @State private var groupName = ""
    @State private var isGroup = false
    @State private var isSearching = false
    @State private var isCreating = false
    @State private var error: String?

    private let searchService = SearchService()
    private let conversationService = ConversationService()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Mode toggle
                Picker("Type", selection: $isGroup) {
                    Text("Direct").tag(false)
                    Text("Group").tag(true)
                }
                .pickerStyle(.segmented)
                .padding()

                if isGroup {
                    TextField("Group Name", text: $groupName)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)
                }

                if !selectedUsers.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(selectedUsers) { user in
                                HStack(spacing: 4) {
                                    AvatarView(url: user.avatarUrl, name: user.displayLabel, size: 24)
                                    Text(user.displayLabel)
                                        .font(.caption)
                                    Button {
                                        selectedUsers.removeAll { $0.id == user.id }
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.caption)
                                    }
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.gray.opacity(0.15))
                                .clipShape(Capsule())
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 8)
                }

                SearchBar(text: $searchQuery, placeholder: "Search users...")
                    .padding(.horizontal)
                    .onChange(of: searchQuery) {
                        search()
                    }

                if isSearching {
                    ProgressView()
                        .padding()
                } else {
                    List(searchResults) { profile in
                        Button {
                            selectUser(profile)
                        } label: {
                            HStack(spacing: 12) {
                                AvatarView(url: profile.avatarUrl, name: profile.displayLabel, size: 40)

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

                                if selectedUsers.contains(where: { $0.id == profile.id }) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(NauticalTheme.ocean)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }

                if let error {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding()
                }
            }
            .navigationTitle("New Conversation")
            #if os(iOS) || os(visionOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createConversation()
                    }
                    .disabled(selectedUsers.isEmpty || isCreating || (isGroup && groupName.isEmpty))
                }
            }
        }
    }

    private func search() {
        guard !searchQuery.isEmpty else {
            searchResults = []
            return
        }

        Task {
            isSearching = true
            defer { isSearching = false }
            searchResults = (try? await searchService.searchProfiles(query: searchQuery)) ?? []
        }
    }

    private func selectUser(_ profile: Profile) {
        if isGroup {
            if selectedUsers.contains(where: { $0.id == profile.id }) {
                selectedUsers.removeAll { $0.id == profile.id }
            } else {
                selectedUsers.append(profile)
            }
        } else {
            selectedUsers = [profile]
            createConversation()
        }
    }

    private func createConversation() {
        Task {
            isCreating = true
            defer { isCreating = false }

            do {
                if isGroup {
                    let conversation = try await conversationService.createGroupConversation(
                        name: groupName,
                        participantIds: selectedUsers.map(\.id)
                    )
                    onCreated(conversation.id)
                } else if let user = selectedUsers.first {
                    let convId = try await conversationService.createDirectConversation(otherUserId: user.id)
                    onCreated(convId)
                }
                dismiss()
            } catch {
                self.error = ErrorSanitizer.sanitize(error)
            }
        }
    }
}

#if DEBUG
#Preview {
    NewConversationView(onCreated: { _ in })
}
#endif
