import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(SettingsViewModel.self) private var settingsViewModel

    var body: some View {
        Group {
            switch authViewModel.state {
            case .loading:
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .unauthenticated, .authenticating:
                LoginView()

            case .needsMFAEnrollment:
                MFASetupView()

            case .needsMFAVerification(let factorId):
                MFAVerifyView(factorId: factorId)

            case .authenticated:
                #if os(iOS) || os(visionOS)
                MainTabView()
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
#endif
