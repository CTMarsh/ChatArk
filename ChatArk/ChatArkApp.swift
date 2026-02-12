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
                    // Trigger new conversation
                }
                .keyboardShortcut("n", modifiers: .command)

                Button("Search") {
                    // Trigger search
                }
                .keyboardShortcut("f", modifiers: .command)
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
