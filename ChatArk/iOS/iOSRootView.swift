import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(SettingsViewModel.self) private var settingsViewModel
    /// Compact width is a phone and iPhone Duo's OUTER display; regular width
    /// is an iPad and Duo's INNER display.
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        Group {
            switch authViewModel.state {
            case .loading:
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .unauthenticated, .authenticating:
                LoginView()

            case .needsEmailConfirmation(let email):
                EmailConfirmationView(email: email)

            case .needsMFAEnrollment:
                MFASetupView()

            case .needsMFAVerification(let factorId):
                MFAVerifyView(factorId: factorId)

            case .authenticated:
                #if os(iOS) || os(visionOS)
                VStack(spacing: 0) {
                    if !NetworkMonitor.shared.isConnected {
                        OfflineBanner()
                    }
                    #if os(iOS)
                    // Chosen by size class, not device idiom.
                    //
                    // This was `UIDevice.current.userInterfaceIdiom == .pad`,
                    // which is fixed for the life of the process. On iPhone Duo
                    // the idiom is always `.phone`, so the 7.6-inch inner
                    // display would have been served the compact tab layout
                    // forever and SplitChatView -- which already exists and is
                    // already good -- would never have appeared on it.
                    //
                    // Apple's guidance is explicit: adapt on size class. The
                    // conversation list beside the thread is their own Mail
                    // example for the inner display.
                    if horizontalSizeClass == .regular {
                        SplitChatView()
                    } else {
                        MainTabView()
                    }
                    #else
                    MainTabView()
                    #endif
                }
                .task {
                    await settingsViewModel.loadPreferences()
                }
                #else
                Text("Unsupported platform")
                #endif
            }
        }
        .animation(.easeInOut, value: authViewModel.isAuthenticated)
        .task {
            await authViewModel.initialize()
        }
    }
}

#if os(iOS) || os(visionOS)
struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Chats", systemImage: "bubble.left.and.bubble.right.fill", value: 0) {
                ConversationListView()
            }

            Tab("Search", systemImage: "magnifyingglass", value: 1) {
                NavigationStack {
                    UserSearchView { profile in
                        // Navigate to conversation with user
                    }
                }
            }

            Tab("Settings", systemImage: "gearshape.fill", value: 2) {
                NavigationStack {
                    SettingsView()
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    RootView()
        .environment(AuthViewModel())
        .environment(SettingsViewModel())
}
#endif
#endif
