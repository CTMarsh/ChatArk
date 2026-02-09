import Foundation
import SwiftUI
import Supabase
import Auth

enum AuthState: Sendable {
    case loading
    case unauthenticated
    case authenticating
    case needsMFAEnrollment
    case needsMFAVerification(factorId: String)
    case authenticated(User)
}

@MainActor
@Observable
final class AuthViewModel {
    var state: AuthState = .loading
    var error: String?
    var isLoading = false

    // MFA enrollment state
    var mfaQrCode: String?
    var mfaSecret: String?
    var mfaFactorId: String?

    private let authService: AuthService

    init(authService: AuthService = AuthService()) {
        self.authService = authService
    }

    // MARK: - Initialize

    func initialize() async {
        do {
            if let session = try? await authService.currentSession {
                let aal = try await authService.getAssuranceLevel()
                let factors = try await authService.getMFAFactors()

                if factors.isEmpty {
                    state = .needsMFAEnrollment
                } else if aal.currentLevel == "aal1" {
                    if let factor = factors.first {
                        state = .needsMFAVerification(factorId: factor.id)
                    }
                } else {
                    state = .authenticated(session.user)
                    SharedDataWriter.shared.writeCurrentUser(
                        id: session.user.id.uuidString,
                        name: session.user.email ?? "User"
                    )
                }
            } else {
                state = .unauthenticated
            }
        } catch {
            state = .unauthenticated
        }

        // Listen for auth state changes
        Task {
            for await (event, session) in authService.authStateChanges {
                await handleAuthEvent(event, session: session)
            }
        }
    }

    // MARK: - Sign In

    func signIn(email: String, password: String) async {
        error = nil
        isLoading = true
        defer { isLoading = false }

        do {
            state = .authenticating
            _ = try await authService.signIn(email: email, password: password)
            let factors = try await authService.getMFAFactors()

            if factors.isEmpty {
                state = .needsMFAEnrollment
            } else if let factor = factors.first {
                state = .needsMFAVerification(factorId: factor.id)
            }
        } catch {
            self.error = error.localizedDescription
            state = .unauthenticated
        }
    }

    // MARK: - Sign Up

    func signUp(email: String, password: String) async {
        error = nil
        isLoading = true
        defer { isLoading = false }

        do {
            _ = try await authService.signUp(email: email, password: password)
            // After signup, sign in
            _ = try await authService.signIn(email: email, password: password)
            state = .needsMFAEnrollment
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Sign Out

    func signOut() async {
        do {
            try await authService.signOut()
            state = .unauthenticated
            SharedDataWriter.shared.clearAll()
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - MFA Enrollment

    func enrollMFA() async {
        error = nil
        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await authService.enrollMFA()
            mfaFactorId = response.id
            mfaQrCode = response.totp?.qrCode
            mfaSecret = response.totp?.secret
        } catch {
            self.error = error.localizedDescription
        }
    }

    func verifyMFAEnrollment(code: String) async {
        error = nil
        isLoading = true
        defer { isLoading = false }

        guard let factorId = mfaFactorId else {
            error = "MFA factor not found"
            return
        }

        do {
            let challenge = try await authService.createMFAChallenge(factorId: factorId)
            try await authService.verifyMFA(
                factorId: factorId,
                challengeId: challenge.id,
                code: code
            )

            if let user = authService.currentUser {
                state = .authenticated(user)
                SharedDataWriter.shared.writeCurrentUser(
                    id: user.id.uuidString,
                    name: user.email ?? "User"
                )
            }
            mfaQrCode = nil
            mfaSecret = nil
            mfaFactorId = nil
        } catch {
            self.error = "Invalid verification code"
        }
    }

    // MARK: - MFA Verification (Returning User)

    func verifyMFA(factorId: String, code: String) async {
        error = nil
        isLoading = true
        defer { isLoading = false }

        do {
            let challenge = try await authService.createMFAChallenge(factorId: factorId)
            try await authService.verifyMFA(
                factorId: factorId,
                challengeId: challenge.id,
                code: code
            )

            if let user = authService.currentUser {
                state = .authenticated(user)
                SharedDataWriter.shared.writeCurrentUser(
                    id: user.id.uuidString,
                    name: user.email ?? "User"
                )
            }
        } catch {
            self.error = "Invalid verification code"
        }
    }

    // MARK: - Password Reset

    func resetPassword(email: String) async {
        error = nil
        isLoading = true
        defer { isLoading = false }

        do {
            try await authService.resetPassword(email: email)
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Auth Event Handler

    private func handleAuthEvent(_ event: AuthChangeEvent, session: Session?) async {
        switch event {
        case .signedIn:
            if let user = session?.user {
                let factors = (try? await authService.getMFAFactors()) ?? []
                if factors.isEmpty {
                    state = .needsMFAEnrollment
                } else {
                    let aal = try? await authService.getAssuranceLevel()
                    if aal?.currentLevel == "aal2" {
                        state = .authenticated(user)
                    }
                }
            }
        case .signedOut:
            state = .unauthenticated
        case .tokenRefreshed:
            break
        default:
            break
        }
    }

    // MARK: - Computed Properties

    var currentUser: User? {
        if case .authenticated(let user) = state { return user }
        return nil
    }

    var isAuthenticated: Bool {
        if case .authenticated = state { return true }
        return false
    }
}
