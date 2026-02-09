import Foundation
import Supabase

@MainActor
final class SearchService {
    private let client: SupabaseClient

    nonisolated init(client: SupabaseClient = supabaseClient) {
        self.client = client
    }

    func searchMessages(query: String, conversationId: UUID? = nil, limit: Int = 50) async throws -> [Message] {
        var dbQuery = client.from("messages")
            .select()
            .textSearch("search_vector", query: query)
            .is("deleted_at", value: nil)

        if let conversationId {
            dbQuery = dbQuery.eq("conversation_id", value: conversationId.uuidString)
        }

        return try await dbQuery
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
    }

    func searchProfiles(query: String, limit: Int = 20) async throws -> [Profile] {
        guard let userId = client.auth.currentUser?.id else {
            throw ChatError.notAuthenticated
        }

        // Get blocked users to exclude
        let blockedUsers: [BlockedUser] = try await client.from("blocked_users")
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value

        let blockedIds = blockedUsers.map(\.blockedUserId.uuidString)

        var dbQuery2 = client.from("profiles")
            .select()
            .or("username.ilike.%\(query)%,display_name.ilike.%\(query)%")
            .neq("id", value: userId.uuidString)

        if !blockedIds.isEmpty {
            dbQuery2 = dbQuery2.not("id", operator: .in, value: blockedIds)
        }

        return try await dbQuery2
            .limit(limit)
            .execute()
            .value
    }
}
