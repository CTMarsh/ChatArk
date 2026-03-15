import Foundation
import Supabase
@preconcurrency import KeychainAccess

nonisolated let supabaseClient: SupabaseClient = {
    let config = SupabaseConfig.current
    return SupabaseClient(
        supabaseURL: config.url,
        supabaseKey: config.anonKey,
        options: SupabaseClientOptions(
            auth: SupabaseClientOptions.AuthOptions(
                storage: KeychainAuthStorage()
            )
        )
    )
}()

final class SupabaseManager: Sendable {
    static let shared = SupabaseManager()
    let client: SupabaseClient

    private init() {
        client = supabaseClient
    }
}

// MARK: - Configuration

struct SupabaseConfig: Sendable {
    let url: URL
    let anonKey: String

    static let development = SupabaseConfig(
        url: URL(string: "https://supabase.noahsark.me")!,
        anonKey: "eyJhbGciOiAiSFMyNTYiLCAidHlwIjogIkpXVCJ9.eyJyb2xlIjogImFub24iLCAiaXNzIjogInN1cGFiYXNlIiwgImlhdCI6IDE3NzM0OTQzNDUsICJleHAiOiAyMDg4ODU0MzQ1fQ.RZNrSXdkB2sBGxMKDIPqMlHoqLAoxypac_t2G6D4Tv8"
    )

    static let production = SupabaseConfig(
        url: URL(string: "https://supabase.noahsark.me")!,
        anonKey: "eyJhbGciOiAiSFMyNTYiLCAidHlwIjogIkpXVCJ9.eyJyb2xlIjogImFub24iLCAiaXNzIjogInN1cGFiYXNlIiwgImlhdCI6IDE3NzM0OTQzNDUsICJleHAiOiAyMDg4ODU0MzQ1fQ.RZNrSXdkB2sBGxMKDIPqMlHoqLAoxypac_t2G6D4Tv8"
    )

    static var current: SupabaseConfig {
        #if DEBUG
        return .development
        #else
        return .production
        #endif
    }
}

// MARK: - Keychain Auth Storage

final class KeychainAuthStorage: AuthLocalStorage, @unchecked Sendable {
    private let keychain: Keychain

    init() {
        keychain = Keychain(service: "com.chrismarsh.chatark.auth")
            .accessibility(.afterFirstUnlockThisDeviceOnly)
            .synchronizable(false)
    }

    func store(key: String, value: Data) throws {
        try keychain.set(value, key: key)
    }

    func retrieve(key: String) throws -> Data? {
        try keychain.getData(key)
    }

    func remove(key: String) throws {
        try keychain.remove(key)
    }
}
