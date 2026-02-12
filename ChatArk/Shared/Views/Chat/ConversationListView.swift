import SwiftUI
import Auth

struct ConversationListView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var viewModel = ConversationListViewModel()
    @State private var showNewConversation = false
    @State private var showMessageSearch = false
    @State private var selectedConversation: ConversationWithDetails?
    @State private var conversationToDelete: ConversationWithDetails?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.conversations.isEmpty {
                    ProgressView("Loading conversations...")
                } else if viewModel.conversations.isEmpty {
                    ContentUnavailableView {
                        Label("No Conversations", systemImage: "bubble.left.and.bubble.right")
                    } description: {
                        Text("Start chatting by tapping the compose button above.")
                    } actions: {
                        Button {
                            showNewConversation = true
                        } label: {
                            Text("New Conversation")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        SearchBar(text: $viewModel.searchQuery)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))

                        ForEach(viewModel.filteredConversations) { detail in
                            NavigationLink(value: detail) {
                                ConversationRow(
                                    detail: detail,
                                    currentUserId: authViewModel.currentUser?.id
                                )
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    conversationToDelete = detail
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .refreshable {
                        await viewModel.loadConversations()
                    }
                }
            }
            .navigationTitle("Chats")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showNewConversation = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                }

                ToolbarItem {
                    Button {
                        showMessageSearch = true
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                }

                ToolbarItem(placement: .navigation) {
                    NavigationLink(value: "settings") {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .navigationDestination(for: ConversationWithDetails.self) { detail in
                ChatView(conversationId: detail.id, title: detail.conversation.name ?? "Chat")
            }
            .navigationDestination(for: String.self) { value in
                if value == "settings" {
                    SettingsView()
                }
            }
            .confirmationDialog(
                "Delete Conversation",
                isPresented: Binding(
                    get: { conversationToDelete != nil },
                    set: { if !$0 { conversationToDelete = nil } }
                ),
                presenting: conversationToDelete
            ) { detail in
                Button("Delete", role: .destructive) {
                    guard let userId = authViewModel.currentUser?.id else { return }
                    Task { await viewModel.deleteConversation(detail, currentUserId: userId) }
                }
            } message: { detail in
                Text("You will leave this conversation and it will be removed from your list.")
            }
            .sheet(isPresented: $showNewConversation) {
                NewConversationView { conversationId in
                    showNewConversation = false
                    Task { await viewModel.loadConversations() }
                }
            }
            .sheet(isPresented: $showMessageSearch) {
                MessageSearchView(conversationId: nil)
            }
        }
        .task {
            await viewModel.loadConversations()
            await viewModel.subscribe()
        }
    }
}

#if DEBUG
#Preview {
    ConversationListView()
        .environment(AuthViewModel())
}
#endif
