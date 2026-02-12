#if os(watchOS)
import SwiftUI
import Supabase

struct WatchProfileView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var profile: Profile?
    @State private var isLoading = true
    private let presenceService = PresenceService()

    var body: some View {
        List {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
            } else if let profile {
                avatarSection(profile)
                detailsSection(profile)
                statusSection(profile)
            }
        }
        .navigationTitle("Profile")
        .task {
            await loadProfile()
        }
    }

    private func avatarSection(_ profile: Profile) -> some View {
        Section {
            VStack(spacing: 8) {
                AvatarView(
                    url: profile.avatarUrl,
                    name: profile.displayLabel,
                    size: 60
                )
                Text(profile.displayLabel)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .listRowBackground(Color.clear)
        }
    }

    private func detailsSection(_ profile: Profile) -> some View {
        Section("Details") {
            if let username = profile.username {
                HStack {
                    Text("Username")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("@\(username)")
                        .font(.caption)
                }
            }
            if let email = profile.email {
                HStack {
                    Text("Email")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(email)
                        .font(.caption2)
                        .lineLimit(1)
                }
            }
        }
    }

    private func statusSection(_ profile: Profile) -> some View {
        Section("Status") {
            NavigationLink {
                WatchStatusView()
            } label: {
                HStack {
                    StatusIndicator(status: profile.status ?? .online, size: 10)
                    Text((profile.status ?? .online).rawValue.capitalized)
                        .font(.caption)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func loadProfile() async {
        guard let userId = authViewModel.currentUser?.id else {
            isLoading = false
            return
        }
        do {
            profile = try await presenceService.fetchProfile(userId: userId)
        } catch {
            // Silently fail — user sees empty state
        }
        isLoading = false
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        WatchProfileView()
    }
    .environment(AuthViewModel())
}
#endif
#endif
