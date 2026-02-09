import Foundation
import Supabase

@MainActor
final class PresenceService {
    private let client: SupabaseClient

    nonisolated init(client: SupabaseClient = supabaseClient) {
        self.client = client
    }

    func updateStatus(_ status: UserStatus) async throws {
        guard let userId = client.auth.currentUser?.id else { return }

        try await client.from("profiles")
            .update([
                "status": AnyJSON.string(status.rawValue),
                "last_seen_at": AnyJSON.string(ISO8601DateFormatter().string(from: Date())),
            ])
            .eq("id", value: userId.uuidString)
            .execute()
    }

    func setOnline() async throws {
        try await updateStatus(.online)
    }

    func setOffline() async throws {
        try await updateStatus(.offline)
    }

    func fetchProfile(userId: UUID) async throws -> Profile {
        try await client.from("profiles")
            .select()
            .eq("id", value: userId.uuidString)
            .single()
            .execute()
            .value
    }

    func searchProfiles(query: String, limit: Int = 20) async throws -> [Profile] {
        try await client.from("profiles")
            .select()
            .or("username.ilike.%\(query)%,display_name.ilike.%\(query)%")
            .limit(limit)
            .execute()
            .value
    }
}
