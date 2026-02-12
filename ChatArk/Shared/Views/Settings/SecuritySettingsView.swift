import SwiftUI
import Auth

struct SecuritySettingsView: View {
    @State private var mfaFactors: [Factor] = []
    @State private var isLoading = true
    @State private var showPasswordChange = false
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var error: String?

    private let authService = AuthService()

    var body: some View {
        Form {
            Section("Multi-Factor Authentication") {
                if mfaFactors.isEmpty {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("MFA not configured")
                    }
                } else {
                    ForEach(mfaFactors, id: \.id) { factor in
                        HStack {
                            Image(systemName: "lock.shield.fill")
                                .foregroundStyle(.green)
                            VStack(alignment: .leading) {
                                Text("TOTP Authenticator")
                                    .font(.body)
                                Text("Active")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                }
            }

            Section("Password") {
                Button("Change Password") {
                    showPasswordChange = true
                }
            }
        }
        .navigationTitle("Security")
        .sheet(isPresented: $showPasswordChange) {
            NavigationStack {
                Form {
                    SecureField("New Password", text: $newPassword)
                        .textContentType(.newPassword)

                    if let error {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }

                    Button("Update Password") {
                        Task {
                            do {
                                try await authService.updatePassword(newPassword: newPassword)
                                showPasswordChange = false
                            } catch {
                                self.error = error.localizedDescription
                            }
                        }
                    }
                    .disabled(newPassword.count < 8)
                }
                .navigationTitle("Change Password")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showPasswordChange = false }
                    }
                }
            }
        }
        .task {
            mfaFactors = (try? await authService.getMFAFactors()) ?? []
            isLoading = false
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        SecuritySettingsView()
    }
}
#endif
