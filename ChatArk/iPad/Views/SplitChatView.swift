import SwiftUI
import Auth

struct SplitChatView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(\.openWindow) private var openWindow
    @State private var viewModel = ConversationListViewModel()
    @State private var workspaceViewModel = WorkspaceViewModel()
    @State private var selectedWorkspace: Workspace?
    @State private var selectedConversation: ConversationWithDetails?
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    @State private var showNewConversation = false
    @State private var isSearchFocused = false
    @State private var showSettings = false
    @State private var showSearch = false

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebarContent
        } detail: {
            detailContent
        }
        .sheet(isPresented: $showNewConversation) {
            NewConversationView { _ in
                showNewConversation = false
            }
        }
        .iPadKeyboardShortcuts(
            onNewConversation: { showNewConversation = true },
            onSearch: { isSearchFocused = true },
            onOpenSettings: { showSettings = true; showSearch = false }
        )
        .task {
            await viewModel.loadConversations()
            await viewModel.subscribe()
            await workspaceViewModel.loadWorkspaces()
        }
    }

    // MARK: - Sidebar

    private var sidebarContent: some View {
        VStack(spacing: 0) {
            // Workspace picker header
            if workspaceViewModel.workspaces.count > 1 {
                workspacePicker
                Divider()
            }

            List(selection: $selectedConversation) {
                // Conversations section
                Section {
                    ForEach(viewModel.filteredConversations) { detail in
                        ConversationRow(detail: detail, currentUserId: authViewModel.currentUser?.id)
                            .tag(detail)
                            .contextMenu {
                                Button {
                                    openWindow(value: detail.id)
                                } label: {
                                    Label("Open in New Window", systemImage: "macwindow.badge.plus")
                                }
                            }
                    }
                }

                // Navigation section
                Section {
                    Button {
                        showSearch = true
                        showSettings = false
                        selectedConversation = nil
                    } label: {
                        Label("People", systemImage: "magnifyingglass")
                    }
                    .foregroundStyle(showSearch ? .primary : .secondary)

                    Button {
                        showSettings = true
                        showSearch = false
                        selectedConversation = nil
                    } label: {
                        Label("Settings", systemImage: "gearshape")
                    }
                    .foregroundStyle(showSettings ? .primary : .secondary)
                }
            }
            .listStyle(.sidebar)
        }
        .navigationTitle("Chats")
        .searchable(text: $viewModel.searchQuery, isPresented: $isSearchFocused, prompt: "Search conversations")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showNewConversation = true
                } label: {
                    Image(systemName: "square.and.pencil")
                }
            }
        }
        .refreshable {
            await viewModel.loadConversations()
        }
        .onChange(of: selectedConversation) {
            if selectedConversation != nil {
                showSettings = false
                showSearch = false
            }
        }
    }

    // MARK: - Detail

    @ViewBuilder
    private var detailContent: some View {
        if showSettings {
            NavigationStack {
                SettingsView()
            }
        } else if showSearch {
            NavigationStack {
                UserSearchView { _ in }
            }
        } else if let conversation = selectedConversation {
            ChatView(
                conversationId: conversation.id,
                title: conversation.conversation.name ?? "Chat"
            )
        } else {
            ContentUnavailableView(
                "Select a Conversation",
                systemImage: "bubble.left.and.bubble.right",
                description: Text("Choose a conversation from the sidebar to start chatting")
            )
        }
    }

    // MARK: - Workspace Picker

    private var workspacePicker: some View {
        Menu {
            Button("All Workspaces") {
                selectedWorkspace = nil
            }
            Divider()
            ForEach(workspaceViewModel.workspaces) { workspace in
                Button(workspace.name) {
                    selectedWorkspace = workspace
                }
            }
        } label: {
            HStack {
                Text(selectedWorkspace?.name ?? "All Workspaces")
                    .font(.headline)
                Image(systemName: "chevron.down")
                    .font(.caption)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
}

#if DEBUG
#Preview {
    SplitChatView()
        .environment(AuthViewModel())
}
#endif
