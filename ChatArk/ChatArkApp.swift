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
        guard url.scheme == "chatark" else { return }

        switch url.host {
        case "conversation":
            if let idString = url.pathComponents.dropFirst().first,
               let id = UUID(uuidString: idString) {
                deepLinkConversationId = id
            }
        case "share":
            // Validate shareId is a UUID to prevent path traversal
            if let shareId = url.pathComponents.dropFirst().first,
               UUID(uuidString: shareId) != nil {
                Task {
                    await PendingShareHandler.shared.processPendingShare(shareId: shareId)
                }
            }
        default:
            break
        }
    }
}
