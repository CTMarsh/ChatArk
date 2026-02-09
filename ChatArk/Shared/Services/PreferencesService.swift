import Foundation
import Supabase

@MainActor
final class PreferencesService {
    private let client: SupabaseClient

    nonisolated init(client: SupabaseClient = supabaseClient) {
        self.client = client
    }

    func fetchPreferences() async throws -> UserPreferences? {
        guard let userId = client.auth.currentUser?.id else {
            throw ChatError.notAuthenticated
        }

        let preferences: [UserPreferences] = try await client.from("user_preferences")
            .select()
            .eq("user_id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value

        return preferences.first
    }

    func updatePreference(key: String, value: AnyJSON) async throws {
        guard let userId = client.auth.currentUser?.id else {
            throw ChatError.notAuthenticated
        }

        try await client.from("user_preferences")
            .update([key: value, "updated_at": AnyJSON.string(ISO8601DateFormatter().string(from: Date()))])
            .eq("user_id", value: userId.uuidString)
            .execute()
    }

    func updatePreferences(_ updates: [String: AnyJSON]) async throws {
        guard let userId = client.auth.currentUser?.id else {
            throw ChatError.notAuthenticated
        }

        var allUpdates = updates
        allUpdates["updated_at"] = .string(ISO8601DateFormatter().string(from: Date()))

        try await client.from("user_preferences")
            .update(allUpdates)
            .eq("user_id", value: userId.uuidString)
            .execute()
    }

    func createDefaultPreferences() async throws -> UserPreferences {
        guard let userId = client.auth.currentUser?.id else {
            throw ChatError.notAuthenticated
        }

        return try await client.from("user_preferences")
            .insert(["user_id": AnyJSON.string(userId.uuidString)])
            .select()
            .single()
            .execute()
            .value
    }
}
