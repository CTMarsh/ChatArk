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
    @State private var showNewConversation = false
    @State private var isSearchFocused = false

    private func updateDockBadge() {
        let count = conversationViewModel.totalUnreadCount
        NSApplication.shared.dockTile.badgeLabel = count > 0 ? "\(count)" : nil
    }

    private var windowTitle: String {
        if let conversation = selectedConversation {
            return conversation.conversation.name ?? "Chat"
        }
        return "ChatArk"
    }

    private var windowSubtitle: String {
        selectedWorkspace?.name ?? ""
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            workspaceSidebar
        } content: {
            conversationList
        } detail: {
            detailView
        }
        .navigationTitle(windowTitle)
        .navigationSubtitle(windowSubtitle)
        .focusedSceneValue(\.newConversationCommand) { showNewConversation = true }
        .focusedSceneValue(\.searchCommand) { isSearchFocused = true }
        .sheet(isPresented: $showNewConversation) {
            NewConversationView { _ in
                showNewConversation = false
            }
            .frame(minWidth: 400, minHeight: 300)
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

    // MARK: - Column 1: Workspaces

    private var workspaceSidebar: some View {
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
    }

    // MARK: - Column 2: Conversations

    private var conversationList: some View {
        List(conversationViewModel.filteredConversations, selection: $selectedConversation) { detail in
            ConversationRow(detail: detail, currentUserId: authViewModel.currentUser?.id)
                .tag(detail)
        }
        .listStyle(.sidebar)
        .searchable(text: $conversationViewModel.searchQuery, isPresented: $isSearchFocused, prompt: "Search")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showNewConversation = true
                } label: {
                    Image(systemName: "square.and.pencil")
                }
                .help("New Conversation")
            }
            ToolbarItem(placement: .automatic) {
                Button {
                    withAnimation {
                        if columnVisibility == .all {
                            columnVisibility = .doubleColumn
                        } else {
                            columnVisibility = .all
                        }
                    }
                } label: {
                    Image(systemName: "sidebar.left")
                }
                .help("Toggle Sidebar")
            }
        }
        .frame(minWidth: 250)
    }

    // MARK: - Column 3: Detail

    @ViewBuilder
    private var detailView: some View {
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
}

#if DEBUG
#Preview {
    MainWindow()
        .environment(AuthViewModel())
}
#endif
#endif
