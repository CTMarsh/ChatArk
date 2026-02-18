import SwiftUI
import Supabase

#if os(macOS)
struct MenuBarExtraContent: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var presenceService = PresenceService()
    @State private var conversationViewModel = ConversationListViewModel()
    @State private var currentStatus: UserStatus = .online
    @State private var unreadCount = 0

    private var statusColor: Color {
        switch currentStatus {
        case .online: .green
        case .away: .yellow
        case .dnd: .red
        case .offline: .gray
        case .suspended: .red
        }
    }

    private var statusLabel: String {
        switch currentStatus {
        case .online: "Online"
        case .away: "Away"
        case .dnd: "Do Not Disturb"
        case .offline: "Invisible"
        case .suspended: "Suspended"
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            if authViewModel.isAuthenticated {
                HStack {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)
                    Text(statusLabel)
                        .font(.caption)
                    Spacer()
                    if unreadCount > 0 {
                        Text("\(unreadCount) unread")
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                }

                Divider()

                Button("Open ChatArk") {
                    NSApplication.shared.activate(ignoringOtherApps: true)
                }

                Button("New Conversation") {
                    NSApplication.shared.activate(ignoringOtherApps: true)
                }
                .keyboardShortcut("n", modifiers: .command)

                Divider()

                Menu("Status") {
                    Button("Online") {
                        Task { try? await presenceService.updateStatus(.online) }
                        currentStatus = .online
                    }
                    Button("Away") {
                        Task { try? await presenceService.updateStatus(.away) }
                        currentStatus = .away
                    }
                    Button("Do Not Disturb") {
                        Task { try? await presenceService.updateStatus(.dnd) }
                        currentStatus = .dnd
                    }
                    Button("Invisible") {
                        Task { try? await presenceService.updateStatus(.offline) }
                        currentStatus = .offline
                    }
                }

                Divider()

                Button("Quit ChatArk") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q", modifiers: .command)
            } else {
                Text("Not signed in")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button("Open ChatArk") {
                    NSApplication.shared.activate(ignoringOtherApps: true)
                }
            }
        }
        .padding(8)
        .frame(width: 220)
        .task {
            guard authViewModel.isAuthenticated else { return }
            await refreshMenuBarData()
        }
        .onChange(of: authViewModel.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated {
                Task { await refreshMenuBarData() }
            } else {
                currentStatus = .online
                unreadCount = 0
            }
        }
    }

    private func refreshMenuBarData() async {
        if let userId = authViewModel.currentUser?.id {
            if let profile = try? await presenceService.fetchProfile(userId: userId) {
                currentStatus = profile.status ?? .online
            }
        }
        await conversationViewModel.loadConversations()
        unreadCount = conversationViewModel.totalUnreadCount
    }
}

#if DEBUG
#Preview {
    MenuBarExtraContent()
        .environment(AuthViewModel())
}
#endif
#endif
