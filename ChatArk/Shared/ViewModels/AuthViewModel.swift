import Foundation
import SwiftUI
import Supabase
import Auth
import UserNotifications
#if canImport(UIKit)
import UIKit
#endif
#if canImport(WatchConnectivity)
import WatchConnectivity
#endif

enum AuthState: Sendable {
    case loading
    case unauthenticated
    case authenticating
    case needsEmailConfirmation(email: String)
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

    // Auth rate limiting — persisted to UserDefaults to survive app restarts
    private var failedLoginAttempts: Int {
        didSet { UserDefaults.standard.set(failedLoginAttempts, forKey: "chatark_failed_login_attempts") }
    }
    private var lockoutUntil: Date? {
        didSet {
            if let lockoutUntil {
                UserDefaults.standard.set(lockoutUntil.timeIntervalSince1970, forKey: "chatark_lockout_until")
            } else {
                UserDefaults.standard.removeObject(forKey: "chatark_lockout_until")
            }
        }
    }
    private static let maxFailedAttempts = 5
    private static let lockoutDurations: [TimeInterval] = [30, 60, 120, 300, 600]

    private let authService: AuthService
    private var sessionRefreshTask: Task<Void, Never>?

    private var deviceUserAgent: String {
        #if os(macOS)
        return "ChatArk/macOS"
        #elseif os(iOS)
        return "ChatArk/iOS \(UIDevice.current.model)"
        #elseif os(watchOS)
        return "ChatArk/watchOS"
        #elseif os(visionOS)
        return "ChatArk/visionOS"
        #else
        return "ChatArk"
        #endif
    }

    init(authService: AuthService = AuthService()) {
        self.authService = authService
        // Restore lockout state from UserDefaults
        self.failedLoginAttempts = UserDefaults.standard.integer(forKey: "chatark_failed_login_attempts")
        let lockoutTimestamp = UserDefaults.standard.double(forKey: "chatark_lockout_until")
        if lockoutTimestamp > 0 {
            let lockoutDate = Date(timeIntervalSince1970: lockoutTimestamp)
            self.lockoutUntil = lockoutDate > Date() ? lockoutDate : nil
        } else {
            self.lockoutUntil = nil
        }
    }

    // MARK: - Initialize

    func initialize() async {
        do {
            // On watchOS, try restoring session from available sources
            #if os(watchOS)
            if (try? await authService.currentSession) == nil {
                var tokens: (accessToken: String, refreshToken: String)?

                // 1. Simulator: read from shared tmp file (both sims share host filesystem)
                #if targetEnvironment(simulator)
                tokens = Self.readSimulatorAuthSession()
                #endif

                // 2. WatchConnectivity (real devices)
                if tokens == nil, WCSession.isSupported() {
                    for _ in 0..<10 {
                        if WCSession.default.activationState == .activated { break }
                        try? await Task.sleep(for: .milliseconds(200))
                    }
                    tokens = WatchConnectivityManager.shared.receivedAuthSession()
                }

                // 3. App Group fallback (real devices with shared container)
                if tokens == nil {
                    tokens = SharedDataWriter.readAuthSession()
                }

                if let tokens {
                    _ = try? await supabaseClient.auth.setSession(
                        accessToken: tokens.accessToken,
                        refreshToken: tokens.refreshToken
                    )
                }
            }
            #endif

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
                    writeAuthSessionToAppGroup(session)
                    registerForPushIfNeeded()
                    try? await authService.trackSession(userAgent: deviceUserAgent)
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

        // On watchOS, listen for auth tokens delivered via WatchConnectivity
        #if os(watchOS)
        Task {
            for await _ in NotificationCenter.default.notifications(named: .watchSessionDidReceiveAuth) {
                await retryWatchAuth()
            }
        }
        #endif
    }

    // MARK: - Sign In

    func signIn(email: String, password: String) async {
        error = nil

        // Check lockout
        if let lockout = lockoutUntil, Date() < lockout {
            let remaining = Int(lockout.timeIntervalSince(Date()))
            self.error = "Too many failed attempts. Try again in \(remaining) seconds."
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            state = .authenticating
            _ = try await authService.signIn(email: email, password: password)
            failedLoginAttempts = 0
            lockoutUntil = nil
            let factors = try await authService.getMFAFactors()

            if factors.isEmpty {
                state = .needsMFAEnrollment
            } else if let factor = factors.first {
                state = .needsMFAVerification(factorId: factor.id)
            }
        } catch {
            failedLoginAttempts += 1
            if failedLoginAttempts >= Self.maxFailedAttempts {
                let index = min(failedLoginAttempts - Self.maxFailedAttempts, Self.lockoutDurations.count - 1)
                lockoutUntil = Date().addingTimeInterval(Self.lockoutDurations[index])
                self.error = "Too many failed attempts. Try again in \(Int(Self.lockoutDurations[index])) seconds."
            } else {
                self.error = ErrorSanitizer.sanitize(error)
            }
            state = .unauthenticated
        }
    }

    // MARK: - Sign Up

    /// Queries the `get_allow_signups` RPC and maps the outcome through `SignupGate`.
    /// The fail-CLOSED rule itself lives in `SignupGate.evaluate` (see SignupGate.swift)
    /// so it can be tested without a Supabase client; this function only performs the call.
    func signupAvailability() async -> SignupAvailability {
        do {
            let allowed = try await authService.checkSignupsAllowed()
            return SignupGate.evaluate(.success(allowed))
        } catch {
            return SignupGate.evaluate(.failure(error))
        }
    }

    func signUp(email: String, password: String) async {
        error = nil
        isLoading = true
        defer { isLoading = false }

        // Re-check before submitting (setting may have changed). Fail CLOSED:
        // only an explicit "allowed" proceeds; disabled or unverified blocks.
        let availability = await signupAvailability()
        guard SignupGate.permitsRegistration(availability) else {
            switch availability {
            case .disabled:
                self.error = "Signups are currently disabled by the platform administrator."
            case .unverified, .allowed:   // .allowed is unreachable: the guard above returned
                self.error = "Couldn't verify signup availability. Please try again."
            }
            return
        }

        do {
            _ = try await authService.signUp(email: email, password: password)
            state = .needsEmailConfirmation(email: email)
        } catch {
            self.error = ErrorSanitizer.sanitize(error)
        }
    }

    // MARK: - Sign Out

    func signOut() async {
        do {
            try? await NotificationService.shared.unregisterDeviceToken()
            try await authService.signOut()
            state = .unauthenticated
            SharedDataWriter.shared.clearAuthSession()
            SharedDataWriter.shared.clearAll()
            #if targetEnvironment(simulator)
            try? FileManager.default.removeItem(atPath: Self.simulatorAuthPath)
            #endif
        } catch {
            self.error = ErrorSanitizer.sanitize(error)
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
            self.error = ErrorSanitizer.sanitize(error)
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
                if let session = try? await authService.currentSession {
                    writeAuthSessionToAppGroup(session)
                }
                registerForPushIfNeeded()
                try? await authService.trackSession(userAgent: deviceUserAgent)
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
                if let session = try? await authService.currentSession {
                    writeAuthSessionToAppGroup(session)
                }
                registerForPushIfNeeded()
                try? await authService.trackSession(userAgent: deviceUserAgent)
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
            self.error = ErrorSanitizer.sanitize(error)
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
                        if let session { writeAuthSessionToAppGroup(session) }
                        registerForPushIfNeeded()
                    }
                }
            }
            sessionRefreshTask?.cancel()
        case .signedOut:
            state = .unauthenticated
            SharedDataWriter.shared.clearAuthSession()
            sessionRefreshTask?.cancel()
        case .tokenRefreshed:
            if let session { writeAuthSessionToAppGroup(session) }
            sessionRefreshTask?.cancel()
        default:
            break
        }
    }

    // MARK: - Session Refresh with Backoff

    func refreshSessionWithRetry() {
        sessionRefreshTask?.cancel()
        sessionRefreshTask = Task {
            var delay: UInt64 = 1_000_000_000 // 1 second
            let maxDelay: UInt64 = 60_000_000_000 // 60 seconds
            let maxAttempts = 5

            for attempt in 1...maxAttempts {
                guard !Task.isCancelled else { return }
                do {
                    let session = try await authService.refreshSession()
                    writeAuthSessionToAppGroup(session)
                    return
                } catch {
                    if attempt == maxAttempts {
                        await MainActor.run {
                            self.error = "Session expired. Please sign in again."
                            self.state = .unauthenticated
                        }
                        return
                    }
                    try? await Task.sleep(nanoseconds: delay)
                    delay = min(delay * 2, maxDelay)
                }
            }
        }
    }

    // MARK: - Watch Auth Retry

    #if os(watchOS)
    private func retryWatchAuth() async {
        guard case .unauthenticated = state else { return }

        var tokens: (accessToken: String, refreshToken: String)?
        #if targetEnvironment(simulator)
        tokens = Self.readSimulatorAuthSession()
        #endif
        if tokens == nil {
            tokens = WatchConnectivityManager.shared.receivedAuthSession()
        }
        guard let tokens else { return }

        _ = try? await supabaseClient.auth.setSession(
            accessToken: tokens.accessToken,
            refreshToken: tokens.refreshToken
        )

        if let session = try? await authService.currentSession {
            let aal = try? await authService.getAssuranceLevel()
            if aal?.currentLevel == "aal2" {
                state = .authenticated(session.user)
            }
        }
    }
    #endif

    // MARK: - Computed Properties

    var currentUser: User? {
        if case .authenticated(let user) = state { return user }
        return nil
    }

    var isAuthenticated: Bool {
        if case .authenticated = state { return true }
        return false
    }

    // MARK: - Session Sharing

    private func writeAuthSessionToAppGroup(_ session: Session) {
        SharedDataWriter.shared.writeAuthSession(
            accessToken: session.accessToken,
            refreshToken: session.refreshToken
        )
        #if os(iOS)
        WatchConnectivityManager.shared.sendAuthSession(
            accessToken: session.accessToken,
            refreshToken: session.refreshToken
        )
        #endif

        // Simulator fallback: write to shared tmp file (both sims share host filesystem)
        #if targetEnvironment(simulator)
        writeSimulatorAuthSession(session)
        #endif
    }

    #if targetEnvironment(simulator)
    private static let simulatorAuthPath: String = {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("chatark-sim", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        return dir.appendingPathComponent("auth.json").path
    }()

    private func writeSimulatorAuthSession(_ session: Session) {
        let payload: [String: String] = [
            "access_token": session.accessToken,
            "refresh_token": session.refreshToken
        ]
        guard let data = try? JSONEncoder().encode(payload) else { return }
        FileManager.default.createFile(atPath: Self.simulatorAuthPath, contents: data, attributes: [.posixPermissions: 0o600])
    }

    private static func readSimulatorAuthSession() -> (accessToken: String, refreshToken: String)? {
        guard let data = FileManager.default.contents(atPath: simulatorAuthPath),
              let payload = try? JSONDecoder().decode([String: String].self, from: data),
              let accessToken = payload["access_token"],
              let refreshToken = payload["refresh_token"] else {
            return nil
        }
        return (accessToken, refreshToken)
    }
    #endif

    func registerForPushIfNeeded() {
        Task {
            let status = await NotificationService.shared.checkPermission()
            guard status == .authorized else { return }
            #if os(iOS)
            UIApplication.shared.registerForRemoteNotifications()
            #elseif os(macOS)
            NSApplication.shared.registerForRemoteNotifications()
            #endif
        }
    }
}
