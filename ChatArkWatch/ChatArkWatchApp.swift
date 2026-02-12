#if os(watchOS)
import SwiftUI
import SwiftData
import WatchConnectivity

@main
struct ChatArkWatchMain: App {
    @State private var authViewModel = AuthViewModel()
    @State private var settingsViewModel = SettingsViewModel()

    init() {
        _ = WatchConnectivityManager.shared
    }

    var body: some Scene {
        WindowGroup {
            WatchRootView()
                .environment(authViewModel)
                .environment(settingsViewModel)
        }
    }
}

struct WatchRootView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(SettingsViewModel.self) private var settingsViewModel

    var body: some View {
        Group {
            switch authViewModel.state {
            case .loading:
                ProgressView()

            case .unauthenticated, .authenticating:
                VStack(spacing: 12) {
                    Image("AppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    Text("ChatArk")
                        .font(.headline)
                    Text("Sign in on your iPhone to get started")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()

            case .needsEmailConfirmation:
                VStack(spacing: 8) {
                    Image(systemName: "envelope.badge")
                        .font(.title)
                    Text("Confirm email on iPhone")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                }

            case .needsMFAEnrollment, .needsMFAVerification:
                VStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .font(.title)
                    Text("Complete MFA on iPhone")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                }

            case .authenticated:
                NavigationStack {
                    WatchConversationList()
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                NavigationLink {
                                    WatchSettingsView()
                                } label: {
                                    Image(systemName: "gear")
                                        .font(.caption)
                                }
                            }
                        }
                }
            }
        }
        .task {
            await authViewModel.initialize()
            await settingsViewModel.loadPreferences()
        }
    }
}
#endif
