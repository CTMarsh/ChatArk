#if os(watchOS)
import SwiftUI
import Supabase

struct WatchSettingsView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(SettingsViewModel.self) private var settingsViewModel
    @State private var showSignOutConfirm = false

    var body: some View {
        List {
            profileSection
            notificationsSection
            statusSection
            accountSection
        }
        .navigationTitle("Settings")
        .confirmationDialog(
            "Sign Out",
            isPresented: $showSignOutConfirm,
            titleVisibility: .visible
        ) {
            Button("Sign Out", role: .destructive) {
                Task { await authViewModel.signOut() }
            }
        } message: {
            Text("You'll need to sign in again on your iPhone.")
        }
    }

    private var profileSection: some View {
        Section {
            NavigationLink {
                WatchProfileView()
            } label: {
                HStack(spacing: 10) {
                    if let user = authViewModel.currentUser {
                        AvatarView(
                            url: nil,
                            name: user.email ?? "User",
                            size: 36
                        )
                        VStack(alignment: .leading, spacing: 2) {
                            Text(user.email ?? "User")
                                .font(.caption)
                                .lineLimit(1)
                            Text("View Profile")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var notificationsSection: some View {
        Section("Notifications") {
            @Bindable var vm = settingsViewModel
            Toggle("Notifications", isOn: Binding(
                get: { vm.desktopNotifications },
                set: {
                    vm.desktopNotifications = $0
                    vm.updatePreference(key: .desktopNotifications, value: .bool($0))
                }
            ))
            .font(.caption)

            Toggle("Do Not Disturb", isOn: Binding(
                get: { vm.dndEnabled },
                set: { vm.toggleDND($0) }
            ))
            .font(.caption)
        }
    }

    private var statusSection: some View {
        Section("Status") {
            NavigationLink {
                WatchStatusView()
            } label: {
                HStack {
                    Image(systemName: "circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.green)
                    Text("Online Status")
                        .font(.caption)
                }
            }
        }
    }

    private var accountSection: some View {
        Section {
            Button(role: .destructive) {
                showSignOutConfirm = true
            } label: {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Sign Out")
                }
                .font(.caption)
            }

            Text("v\(Bundle.main.appVersion) (\(Bundle.main.buildNumber))")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        WatchSettingsView()
    }
    .environment(AuthViewModel())
    .environment(SettingsViewModel())
}
#endif
#endif
