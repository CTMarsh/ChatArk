import SwiftUI
import Auth

#if os(macOS)
struct MainWindow: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var conversationViewModel = ConversationListViewModel()
    @State private var workspaceViewModel = WorkspaceViewModel()
    @State private var selectedWorkspace: Workspace?
    @State private var selectedConversation: ConversationWithDetails?
    @State private var columnVisibility = NavigationSplitViewVisibility.all

    private func updateDockBadge() {
        let count = conversationViewModel.totalUnreadCount
        NSApplication.shared.dockTile.badgeLabel = count > 0 ? "\(count)" : nil
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Column 1: Workspaces
            List(selection: $selectedWorkspace) {
                Section("Workspaces") {
                    ForEach(workspaceViewModel.workspaces) { workspace in
                        Label(workspace.name, systemImage: "building.2")
                            .tag(workspace)
                    }
                }

                Section {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Label("Settings", systemImage: "gearshape")
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("ChatArk")
            .frame(minWidth: 180)
        } content: {
            // Column 2: Conversations
            List(conversationViewModel.filteredConversations, selection: $selectedConversation) { detail in
                ConversationRow(detail: detail, currentUserId: authViewModel.currentUser?.id)
                    .tag(detail)
            }
            .listStyle(.sidebar)
            .searchable(text: $conversationViewModel.searchQuery, prompt: "Search")
            .toolbar {
                ToolbarItem {
                    Button {
                        // New conversation
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .frame(minWidth: 250)
        } detail: {
            // Column 3: Chat
            if let conversation = selectedConversation {
                ChatView(
                    conversationId: conversation.id,
                    title: conversation.conversation.name ?? "Chat"
                )
            } else {
                ContentUnavailableView(
                    "Select a Conversation",
                    systemImage: "bubble.left.and.bubble.right",
                    description: Text("Choose a conversation to start chatting")
                )
            }
        }
        .task {
            await conversationViewModel.loadConversations()
            await conversationViewModel.subscribe()
            await workspaceViewModel.loadWorkspaces()
            updateDockBadge()
        }
        .onChange(of: conversationViewModel.totalUnreadCount) {
            updateDockBadge()
        }
    }
}

#if DEBUG
#Preview {
    MainWindow()
        .environment(AuthViewModel())
}
#endif
#endif
