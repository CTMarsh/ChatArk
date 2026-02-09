import Foundation
import Supabase

@MainActor
final class BlockingService {
    private let client: SupabaseClient

    nonisolated init(client: SupabaseClient = supabaseClient) {
        self.client = client
    }

    func blockUser(blockedUserId: UUID) async throws {
        guard let userId = client.auth.currentUser?.id else {
            throw ChatError.notAuthenticated
        }

        try await client.from("blocked_users")
            .insert([
                "user_id": AnyJSON.string(userId.uuidString),
                "blocked_user_id": AnyJSON.string(blockedUserId.uuidString),
            ])
            .execute()
    }

    func unblockUser(blockedUserId: UUID) async throws {
        guard let userId = client.auth.currentUser?.id else {
            throw ChatError.notAuthenticated
        }

        try await client.from("blocked_users")
            .delete()
            .eq("user_id", value: userId.uuidString)
            .eq("blocked_user_id", value: blockedUserId.uuidString)
            .execute()
    }

    func fetchBlockedUsers() async throws -> [BlockedUser] {
        guard let userId = client.auth.currentUser?.id else {
            throw ChatError.notAuthenticated
        }

        return try await client.from("blocked_users")
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
    }

    func isBlocked(userId: UUID) async throws -> Bool {
        guard let currentUserId = client.auth.currentUser?.id else { return false }

        let result: [BlockedUser] = try await client.from("blocked_users")
            .select()
            .eq("user_id", value: currentUserId.uuidString)
            .eq("blocked_user_id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value

        return !result.isEmpty
    }
}
