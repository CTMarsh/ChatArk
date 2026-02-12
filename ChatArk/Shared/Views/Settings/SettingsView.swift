import SwiftUI

struct SettingsView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var showSignOutConfirm = false

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
                            .font(.caption)
                            .fontWeight(.semibold)
                        Text("Version 1.0.0")
                            .font(.caption2)
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
