import SwiftUI
import SwiftData

@main
struct ChatArkMain: App {
    #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #elseif os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif

    @State private var authViewModel = AuthViewModel()
    @State private var settingsViewModel = SettingsViewModel()
    // FIXME: written by handleDeepLink and never read — opening a chatark://conversation
    // link parses and validates the id, then navigates nowhere. Parsing is now covered by
    // DeepLinkRouteTests; wiring the navigation is a separate change.
    @State private var deepLinkConversationId: UUID?

    #if os(macOS)
    @FocusedValue(\.newConversationCommand) private var newConversationCommand
    @FocusedValue(\.searchCommand) private var searchCommand
    #endif

    var body: some Scene {
        WindowGroup {
            appContent
                .environment(authViewModel)
                .environment(settingsViewModel)
                .preferredColorScheme(settingsViewModel.colorScheme)
                .tint(settingsViewModel._tintColor)
                .modelContainer(CacheManager.shared.container)
                .onOpenURL { url in
                    handleDeepLink(url)
                }
                #if os(macOS)
                .frame(minWidth: 800, minHeight: 500)
                #endif
        }
        #if os(macOS)
        .defaultSize(width: 1100, height: 700)
        .commands {
            CommandGroup(after: .newItem) {
                Button("New Conversation") {
                    newConversationCommand?()
                }
                .keyboardShortcut("n", modifiers: .command)
                .disabled(newConversationCommand == nil)

                Button("Search") {
                    searchCommand?()
                }
                .keyboardShortcut("f", modifiers: .command)
                .disabled(searchCommand == nil)
            }
        }
        #endif

        #if os(iOS)
        WindowGroup(for: UUID.self) { $conversationId in
            if let id = conversationId {
                ConversationWindowGroup(conversationId: id, title: "Chat")
                    .environment(authViewModel)
                    .environment(settingsViewModel)
                    .preferredColorScheme(settingsViewModel.colorScheme)
                    .tint(settingsViewModel._tintColor)
                    .modelContainer(CacheManager.shared.container)
            }
        }
        #endif

        #if os(macOS)
        Settings {
            PreferencesWindow()
                .environment(settingsViewModel)
        }

        MenuBarExtra("ChatArk", systemImage: "bubble.left.and.bubble.right.fill") {
            MenuBarExtraContent()
                .environment(authViewModel)
        }
        #endif
    }

    @ViewBuilder
    private var appContent: some View {
        #if os(macOS)
        MacRootView()
        #elseif os(watchOS)
        WatchRootView()
        #else
        RootView()
        #endif
    }

    private func handleDeepLink(_ url: URL) {
        // Parsing and UUID validation live in DeepLinkRoute so they are unit-testable;
        // this function is only the side effects.
        guard let route = DeepLinkRoute.parse(url) else { return }

        switch route {
        case .conversation(let id):
            deepLinkConversationId = id
        case .share(let rawId):
            Task {
                await PendingShareHandler.shared.processPendingShare(shareId: rawId)
            }
        }
    }
}
