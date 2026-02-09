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
        url: URL(string: "https://bcwfsqldmyyrstxjuruc.supabase.co")!,
        anonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJjd2ZzcWxkbXl5cnN0eGp1cnVjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAyMzE5MzcsImV4cCI6MjA4NTgwNzkzN30.lGXIUJwhXATlgR1t_uzOfu37h7-ibdc0Ybdpt3KxQ6A"
    )

    static let production = SupabaseConfig(
        url: URL(string: "https://xtnqdyjldgmfhtvtggmm.supabase.co")!,
        anonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh0bnFkeWpsZGdtZmh0dnRnZ21tIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAwMTk3MDQsImV4cCI6MjA4NTU5NTcwNH0.Zp_SnwwmPMqp_1VDEJgw1frXgj3A5LJk-c5g6xUaevQ"
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
            .accessibility(.afterFirstUnlock)
            .synchronizable(true)
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
