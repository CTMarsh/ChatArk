import SwiftUI
import Supabase

struct SecuritySettingsView: View {
    @State private var mfaFactors: [Factor] = []
    @State private var sessions: [UserSession] = []
    @State private var isLoading = true
    @State private var showPasswordChange = false
    @State private var showMFASetup = false
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var error: String?
    @State private var showDeleteMFAConfirm: Factor?
    @State private var showSignOutOthersConfirm = false
    @State private var showSignOutAllConfirm = false
    @State private var sessionMessage: String?

    private let authService = AuthService()

    var body: some View {
        Form {
            mfaSection
            passwordSection
            sessionsSection
            signOutSection
        }
        .navigationTitle("Security")
        .sheet(isPresented: $showPasswordChange) {
            passwordChangeSheet
        }
        .sheet(isPresented: $showMFASetup) {
            MFASetupView()
                .environment(AuthViewModel())
                .onDisappear { Task { await reloadMFA() } }
        }
        .confirmationDialog(
            "Remove Authenticator",
            isPresented: Binding(
                get: { showDeleteMFAConfirm != nil },
                set: { if !$0 { showDeleteMFAConfirm = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Remove", role: .destructive) {
                if let factor = showDeleteMFAConfirm {
                    Task { await removeMFAFactor(factor) }
                }
            }
        } message: {
            Text("This will remove the authenticator. You may lose access to your account if this is your only MFA method.")
        }
        .confirmationDialog("Sign Out Other Devices", isPresented: $showSignOutOthersConfirm, titleVisibility: .visible) {
            Button("Sign Out Others", role: .destructive) {
                Task { await signOutOtherSessions() }
            }
        } message: {
            Text("This will sign out all other sessions. Your current session will remain active.")
        }
        .confirmationDialog("Sign Out All Devices", isPresented: $showSignOutAllConfirm, titleVisibility: .visible) {
            Button("Sign Out All", role: .destructive) {
                Task { await signOutAllSessions() }
            }
        } message: {
            Text("This will sign out all sessions including this device. You will need to sign in again.")
        }
        .task {
            await reloadMFA()
            await reloadSessions()
            isLoading = false
        }
    }

    // MARK: - MFA Section

    private var mfaSection: some View {
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
                            Text(factor.friendlyName ?? "Authenticator App")
                                .font(.body)
                            Text("Active")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                        Spacer()
                        Button(role: .destructive) {
                            showDeleteMFAConfirm = factor
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Button {
                showMFASetup = true
            } label: {
                Label("Add Authenticator", systemImage: "plus.circle")
            }
        }
    }

    // MARK: - Password Section

    private var passwordSection: some View {
        Section("Password") {
            Button("Change Password") {
                currentPassword = ""
                newPassword = ""
                confirmPassword = ""
                error = nil
                showPasswordChange = true
            }
        }
    }

    // MARK: - Sessions Section

    private var sessionsSection: some View {
        Section {
            if sessions.isEmpty {
                HStack {
                    Image(systemName: deviceIcon)
                        .foregroundStyle(NauticalTheme.ocean)
                    VStack(alignment: .leading) {
                        Text("This Device")
                            .font(.body)
                        Text("Current session")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                ForEach(sessions) { session in
                    HStack {
                        Image(systemName: sessionDeviceIcon(session))
                            .foregroundStyle(NauticalTheme.ocean)
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(sessionDeviceName(session))
                                    .font(.body)
                                if isCurrentSession(session) {
                                    Text("This device")
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(.green.opacity(0.2))
                                        .foregroundStyle(.green)
                                        .clipShape(Capsule())
                                }
                            }
                            HStack(spacing: 8) {
                                if let lastActive = session.lastActiveAt {
                                    Text(lastActive, style: .relative)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                if let ip = session.ipAddress {
                                    Text(ip)
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                        Spacer()
                        if !isCurrentSession(session) {
                            Button(role: .destructive) {
                                Task { await revokeSession(session) }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            if let sessionMessage {
                Text(sessionMessage)
                    .foregroundStyle(.green)
                    .font(.caption)
            }
        } header: {
            HStack {
                Text("Active Sessions")
                Spacer()
                if sessions.count > 1 {
                    Button("Sign Out Others") {
                        showSignOutOthersConfirm = true
                    }
                    .font(.caption)
                }
            }
        }
    }

    // MARK: - Sign Out Section

    private var signOutSection: some View {
        Section {
            Button(role: .destructive) {
                showSignOutAllConfirm = true
            } label: {
                Text("Sign Out All Devices")
            }
        }
    }

    // MARK: - Password Change Sheet

    private var passwordChangeSheet: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("Current Password", text: $currentPassword)
                        .textContentType(.password)
                }

                Section {
                    SecureField("New Password", text: $newPassword)
                        .textContentType(.newPassword)

                    SecureField("Confirm New Password", text: $confirmPassword)
                        .textContentType(.newPassword)
                }

                if newPassword.count > 0 && newPassword.count < 8 {
                    Text("Password must be at least 8 characters")
                        .foregroundStyle(.orange)
                        .font(.caption)
                }

                if !confirmPassword.isEmpty && newPassword != confirmPassword {
                    Text("Passwords do not match")
                        .foregroundStyle(.red)
                        .font(.caption)
                }

                if let error {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }

                Button("Update Password") {
                    Task {
                        do {
                            try await authService.changePassword(
                                currentPassword: currentPassword,
                                newPassword: newPassword
                            )
                            showPasswordChange = false
                        } catch {
                            self.error = ErrorSanitizer.sanitize(error)
                        }
                    }
                }
                .disabled(!isPasswordValid)
            }
            .navigationTitle("Change Password")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showPasswordChange = false }
                }
            }
        }
    }

    private var isPasswordValid: Bool {
        !currentPassword.isEmpty &&
        newPassword.count >= 8 &&
        newPassword == confirmPassword
    }

    // MARK: - Session Helpers

    private var deviceIcon: String {
        #if os(macOS)
        "laptopcomputer"
        #else
        "iphone"
        #endif
    }

    private func sessionDeviceIcon(_ session: UserSession) -> String {
        let ua = session.userAgent?.lowercased() ?? ""
        if ua.contains("macintosh") || ua.contains("macos") { return "laptopcomputer" }
        if ua.contains("ipad") { return "ipad" }
        if ua.contains("iphone") { return "iphone" }
        if ua.contains("watch") { return "applewatch" }
        return "desktopcomputer"
    }

    private func sessionDeviceName(_ session: UserSession) -> String {
        if let info = session.deviceInfo, let name = info["device_name"] ?? info["name"] {
            return name
        }
        let ua = session.userAgent?.lowercased() ?? ""
        if ua.contains("macintosh") || ua.contains("macos") { return "Mac" }
        if ua.contains("ipad") { return "iPad" }
        if ua.contains("iphone") { return "iPhone" }
        if ua.contains("watch") { return "Apple Watch" }
        return "Unknown Device"
    }

    private func isCurrentSession(_ session: UserSession) -> Bool {
        // Compare session token with current auth session token prefix
        guard let currentToken = try? SupabaseManager.shared.client.auth.currentSession?.accessToken else {
            return false
        }
        return session.sessionToken.hasPrefix(String(currentToken.prefix(16)))
    }

    // MARK: - Actions

    private func reloadMFA() async {
        mfaFactors = (try? await authService.getMFAFactors()) ?? []
    }

    private func reloadSessions() async {
        sessions = (try? await authService.fetchActiveSessions()) ?? []
    }

    private func removeMFAFactor(_ factor: Factor) async {
        do {
            try await authService.unenrollMFA(factorId: factor.id)
            await reloadMFA()
        } catch {
            self.error = ErrorSanitizer.sanitize(error)
        }
    }

    private func revokeSession(_ session: UserSession) async {
        do {
            try await authService.revokeSession(id: session.id)
            sessions.removeAll { $0.id == session.id }
        } catch {
            self.error = ErrorSanitizer.sanitize(error)
        }
    }

    private func signOutOtherSessions() async {
        do {
            try await authService.signOutOtherSessions()
            sessionMessage = "All other sessions have been signed out."
            await reloadSessions()
        } catch {
            self.error = ErrorSanitizer.sanitize(error)
        }
    }

    private func signOutAllSessions() async {
        do {
            try await authService.signOutAllSessions()
        } catch {
            self.error = ErrorSanitizer.sanitize(error)
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
