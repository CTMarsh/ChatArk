import SwiftUI
import Supabase

struct SettingsView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var showSignOutConfirm = false
    @State private var isAdmin = false

    var body: some View {
        List {
            Section {
                NavigationLink {
                    ProfileSettingsView()
                } label: {
                    Label("Profile", systemImage: "person.circle")
                }

                NavigationLink {
                    AppearanceSettingsView()
                } label: {
                    Label("Appearance", systemImage: "paintbrush")
                }

                NavigationLink {
                    MessageSettingsView()
                } label: {
                    Label("Messages", systemImage: "text.bubble")
                }
            }

            Section {
                NavigationLink {
                    NotificationSettingsView()
                } label: {
                    Label("Notifications", systemImage: "bell")
                }

                NavigationLink {
                    PrivacySettingsView()
                } label: {
                    Label("Privacy", systemImage: "hand.raised")
                }

                NavigationLink {
                    SecuritySettingsView()
                } label: {
                    Label("Security", systemImage: "lock.shield")
                }
            }

            Section {
                NavigationLink {
                    AccessibilitySettingsView()
                } label: {
                    Label("Accessibility", systemImage: "accessibility")
                }
            }

            Section {
                NavigationLink {
                    WorkspaceManagementView()
                } label: {
                    Label("Workspaces", systemImage: "building.2")
                }

                NavigationLink {
                    WidgetListSettingsView()
                } label: {
                    Label("Widgets", systemImage: "widget.small")
                }
            }

            if isAdmin {
                Section {
                    NavigationLink {
                        AdminDashboardView()
                    } label: {
                        Label("Platform Admin", systemImage: "shield.lefthalf.filled")
                            .foregroundStyle(.red)
                    }
                }
            }

            Section {
                Button(role: .destructive) {
                    showSignOutConfirm = true
                } label: {
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        .foregroundStyle(.red)
                }
            }

            Section {
                HStack {
                    Spacer()
                    VStack {
                        Text("ChatArk")
                            .arkType(.cap)
                            .fontWeight(.semibold)
                        Text("v\(Bundle.main.appVersion) (\(Bundle.main.buildNumber))")
                            .arkType(.cap)
                            .foregroundStyle(.tertiary)
                    }
                    Spacer()
                }
            }
        }
        .navigationTitle("Settings")
        .confirmationDialog("Sign Out", isPresented: $showSignOutConfirm) {
            Button("Sign Out", role: .destructive) {
                Task { await authViewModel.signOut() }
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .task {
            await checkAdminStatus()
        }
    }

    private func checkAdminStatus() async {
        guard let userId = SupabaseManager.shared.client.auth.currentUser?.id else { return }
        let profile: Profile? = try? await SupabaseManager.shared.client
            .from("profiles")
            .select("id, is_platform_admin")
            .eq("id", value: userId.uuidString)
            .single()
            .execute()
            .value
        isAdmin = profile?.isPlatformAdmin == true
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        SettingsView()
    }
    .environment(AuthViewModel())
}
#endif
