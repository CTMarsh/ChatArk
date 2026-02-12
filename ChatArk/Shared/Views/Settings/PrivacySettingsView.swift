import SwiftUI

struct PrivacySettingsView: View {
    @Environment(SettingsViewModel.self) private var viewModel
    @State private var blockedUsers: [BlockedUser] = []
    @State private var blockedProfiles: [Profile] = []
    private let blockingService = BlockingService()
    private let presenceService = PresenceService()

    var body: some View {
        Form {
            Section("Visibility") {
                Toggle("Show Online Status", isOn: Binding(
                    get: { viewModel.showOnlineStatus },
                    set: { viewModel.toggleOnlineStatus($0) }
                ))

                Toggle("Show Read Receipts", isOn: Binding(
                    get: { viewModel.showReadReceipts },
                    set: { viewModel.toggleReadReceipts($0) }
                ))

                Toggle("Show Typing Indicator", isOn: Binding(
                    get: { viewModel.showTypingIndicator },
                    set: { viewModel.toggleTypingIndicator($0) }
                ))
            }

            Section("Blocked Users") {
                if blockedProfiles.isEmpty {
                    Text("No blocked users")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(blockedProfiles) { profile in
                        HStack {
                            AvatarView(url: profile.avatarUrl, name: profile.displayLabel, size: 36)
                            Text(profile.displayLabel)
                            Spacer()
                            Button("Unblock") {
                                Task {
                                    try? await blockingService.unblockUser(blockedUserId: profile.id)
                                    await loadBlockedUsers()
                                }
                            }
                            .font(.caption)
                            .foregroundStyle(.red)
                        }
                    }
                }
            }
        }
        .navigationTitle("Privacy")
        .task {
            await loadBlockedUsers()
        }
    }

    private func loadBlockedUsers() async {
        blockedUsers = (try? await blockingService.fetchBlockedUsers()) ?? []
        var profiles: [Profile] = []
        for blocked in blockedUsers {
            if let profile = try? await presenceService.fetchProfile(userId: blocked.blockedUserId) {
                profiles.append(profile)
            }
        }
        blockedProfiles = profiles
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        PrivacySettingsView()
    }
    .environment(SettingsViewModel())
}
#endif
