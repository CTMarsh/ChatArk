import SwiftUI
import Auth

struct SplitChatView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var viewModel = ConversationListViewModel()
    @State private var selectedConversation: ConversationWithDetails?
    @State private var columnVisibility = NavigationSplitViewVisibility.all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Sidebar: Conversation list
            List(viewModel.filteredConversations, selection: $selectedConversation) { detail in
                ConversationRow(detail: detail, currentUserId: authViewModel.currentUser?.id)
                    .tag(detail)
            }
            .listStyle(.sidebar)
            .navigationTitle("Chats")
            .searchable(text: $viewModel.searchQuery, prompt: "Search conversations")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        // Show new conversation
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .refreshable {
                await viewModel.loadConversations()
            }
        } detail: {
            // Detail: Chat view
            if let conversation = selectedConversation {
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
        .task {
            await viewModel.loadConversations()
            await viewModel.subscribe()
        }
    }
}
