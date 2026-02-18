import SwiftUI
import SwiftData

#if os(macOS)
struct MacRootView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(SettingsViewModel.self) private var settingsViewModel

    var body: some View {
        ZStack {
            switch authViewModel.state {
            case .loading:
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .unauthenticated, .authenticating:
                LoginView()
                    .frame(width: 400, height: 500)

            case .needsEmailConfirmation(let email):
                EmailConfirmationView(email: email)
                    .frame(width: 400, height: 500)

            case .needsMFAEnrollment:
                MFASetupView()
                    .frame(width: 400, height: 600)

            case .needsMFAVerification(let factorId):
                MFAVerifyView(factorId: factorId)
                    .frame(width: 400, height: 400)

            case .authenticated:
                VStack(spacing: 0) {
                    if !NetworkMonitor.shared.isConnected {
                        OfflineBanner()
                    }
                    MainWindow()
                }
                .task {
                    await settingsViewModel.loadPreferences()
                }
            }
        }
        .task {
            await authViewModel.initialize()
        }
    }
}

#if DEBUG
#Preview {
    MacRootView()
        .environment(AuthViewModel())
        .environment(SettingsViewModel())
}
#endif
#endif
