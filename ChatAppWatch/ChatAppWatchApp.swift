import SwiftUI
import SwiftData

#if os(watchOS)
@main
struct ChatAppWatchMain: App {
    @State private var authViewModel = AuthViewModel()
    @State private var settingsViewModel = SettingsViewModel()

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

    var body: some View {
        Group {
            switch authViewModel.state {
            case .loading:
                ProgressView()

            case .unauthenticated, .authenticating:
                VStack(spacing: 12) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.title)
                        .foregroundStyle(.blue)
                    Text("ChatApp")
                        .font(.headline)
                    Text("Sign in on your iPhone to get started")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()

            case .needsMFAEnrollment, .needsMFAVerification:
                VStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .font(.title)
                    Text("Complete MFA on iPhone")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                }

            case .authenticated:
                WatchConversationList()
            }
        }
        .task {
            await authViewModel.initialize()
        }
    }
}
#endif
