import Foundation
import Supabase
import Auth

@MainActor
final class AuthService: Observable {
    private let client: SupabaseClient

    nonisolated init(client: SupabaseClient = supabaseClient) {
        self.client = client
    }

    // MARK: - Sign Up

    func signUp(email: String, password: String) async throws -> User {
        let response = try await client.auth.signUp(
            email: email,
            password: password
        )
        return response.user
    }

    // MARK: - Sign In

    func signIn(email: String, password: String) async throws -> Session {
        try await client.auth.signIn(
            email: email,
            password: password
        )
    }

    // MARK: - Sign Out

    func signOut() async throws {
        try await client.auth.signOut()
    }

    // MARK: - Password Reset

    func resetPassword(email: String) async throws {
        try await client.auth.resetPasswordForEmail(email)
    }

    func updatePassword(newPassword: String) async throws {
        try await client.auth.update(user: UserAttributes(password: newPassword))
    }

    // MARK: - Session Management

    var currentUser: User? {
        client.auth.currentUser
    }

    var currentSession: Session? {
        get async throws {
            try await client.auth.session
        }
    }

    func refreshSession() async throws -> Session {
        try await client.auth.refreshSession()
    }

    // MARK: - Auth State Changes

    var authStateChanges: AsyncStream<(event: AuthChangeEvent, session: Session?)> {
        AsyncStream { continuation in
            let task = Task {
                for await (event, session) in client.auth.authStateChanges {
                    continuation.yield((event: event, session: session))
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    // MARK: - MFA (Multi-Factor Authentication)

    func enrollMFA() async throws -> AuthMFAEnrollResponse {
        try await client.auth.mfa.enroll(
            params: .totp()
        )
    }

    func createMFAChallenge(factorId: String) async throws -> AuthMFAChallengeResponse {
        try await client.auth.mfa.challenge(
            params: MFAChallengeParams(factorId: factorId)
        )
    }

    func verifyMFA(factorId: String, challengeId: String, code: String) async throws {
        try await client.auth.mfa.verify(
            params: MFAVerifyParams(
                factorId: factorId,
                challengeId: challengeId,
                code: code
            )
        )
    }

    func getMFAFactors() async throws -> [Factor] {
        let response = try await client.auth.mfa.listFactors()
        return response.totp
    }

    func unenrollMFA(factorId: String) async throws {
        try await client.auth.mfa.unenroll(
            params: MFAUnenrollParams(factorId: factorId)
        )
    }

    func getAssuranceLevel() async throws -> AuthMFAGetAuthenticatorAssuranceLevelResponse {
        try await client.auth.mfa.getAuthenticatorAssuranceLevel()
    }

    // MARK: - Profile Management

    func updateProfile(displayName: String? = nil, avatarUrl: String? = nil) async throws {
        var data: [String: AnyJSON] = [:]
        if let displayName {
            data["display_name"] = .string(displayName)
        }
        if let avatarUrl {
            data["avatar_url"] = .string(avatarUrl)
        }
        try await client.auth.update(user: UserAttributes(data: data))
    }
}

// MARK: - Auth Errors

enum AuthError: LocalizedError {
    case signUpFailed
    case sessionExpired
    case mfaRequired
    case mfaNotEnrolled
    case invalidCredentials

    var errorDescription: String? {
        switch self {
        case .signUpFailed: "Failed to create account"
        case .sessionExpired: "Your session has expired. Please sign in again."
        case .mfaRequired: "Multi-factor authentication is required"
        case .mfaNotEnrolled: "Please set up multi-factor authentication"
        case .invalidCredentials: "Invalid email or password"
        }
    }
}
