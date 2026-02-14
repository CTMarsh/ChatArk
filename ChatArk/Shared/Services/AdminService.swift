import Foundation
import Supabase

@MainActor
final class AdminService {
    private let client: SupabaseClient

    nonisolated init(client: SupabaseClient = supabaseClient) {
        self.client = client
    }

    // MARK: - Dashboard

    func getDashboardMetrics() async throws -> DashboardMetrics {
        try await client.rpc("admin_get_dashboard_metrics")
            .execute()
            .value
    }

    // MARK: - Users

    func fetchAllUsers(search: String? = nil) async throws -> [Profile] {
        var query = client.from("profiles")
            .select()

        if let search, !search.isEmpty {
            let sanitized = PostgRESTSanitizer.sanitize(search)
            query = query.or("username.ilike.%\(sanitized)%,display_name.ilike.%\(sanitized)%,email.ilike.%\(sanitized)%")
        }

        return try await query
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    func fetchUser(id: UUID) async throws -> Profile {
        try await client.from("profiles")
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value
    }

    func suspendUser(id: UUID, suspended: Bool) async throws {
        try await client.rpc("admin_set_user_suspended", params: [
            "p_user_id": AnyJSON.string(id.uuidString),
            "p_suspended": AnyJSON.bool(suspended),
        ]).execute()
    }

    func deleteUser(id: UUID) async throws {
        try await client.rpc("admin_delete_user", params: [
            "p_user_id": AnyJSON.string(id.uuidString),
        ]).execute()
    }

    func resetUserMFA(id: UUID) async throws {
        try await client.rpc("admin_reset_user_mfa", params: [
            "p_user_id": AnyJSON.string(id.uuidString),
        ]).execute()
    }

    func setUserAdmin(id: UUID, isAdmin: Bool) async throws {
        try await client.from("profiles")
            .update(["is_platform_admin": AnyJSON.bool(isAdmin)])
            .eq("id", value: id.uuidString)
            .execute()

        try await client.rpc("admin_log_action", params: [
            "p_action": AnyJSON.string(isAdmin ? "admin_granted" : "admin_revoked"),
            "p_target_type": AnyJSON.string("user"),
            "p_target_id": AnyJSON.string(id.uuidString),
        ]).execute()
    }

    func fetchUserWorkspaces(userId: UUID) async throws -> [Workspace] {
        try await client.from("workspaces")
            .select()
            .eq("owner_id", value: userId.uuidString)
            .execute()
            .value
    }

    func fetchUserMemberships(userId: UUID) async throws -> [WorkspaceMember] {
        try await client.from("workspace_members")
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
    }

    // MARK: - Workspaces

    func fetchAllWorkspaces(search: String? = nil) async throws -> [Workspace] {
        var query = client.from("workspaces")
            .select()

        if let search, !search.isEmpty {
            let sanitized = PostgRESTSanitizer.sanitize(search)
            query = query.ilike("name", pattern: "%\(sanitized)%")
        }

        return try await query
            .order("name")
            .execute()
            .value
    }

    func fetchWorkspaceMembers(workspaceId: UUID) async throws -> [WorkspaceMember] {
        try await client.from("workspace_members")
            .select()
            .eq("workspace_id", value: workspaceId.uuidString)
            .execute()
            .value
    }

    func fetchWorkspaceWidgets(workspaceId: UUID) async throws -> [WorkspaceWidget] {
        try await client.from("widgets")
            .select()
            .eq("workspace_id", value: workspaceId.uuidString)
            .execute()
            .value
    }

    func suspendWorkspace(id: UUID, suspended: Bool) async throws {
        try await client.rpc("admin_set_workspace_suspended", params: [
            "p_workspace_id": AnyJSON.string(id.uuidString),
            "p_suspended": AnyJSON.bool(suspended),
        ]).execute()
    }

    // MARK: - Audit Log

    func fetchAuditLogs(action: String? = nil) async throws -> [AdminAuditLog] {
        var query = client.from("admin_audit_logs")
            .select("id, admin_id, action, target_type, target_id, created_at")

        if let action, !action.isEmpty {
            query = query.eq("action", value: action)
        }

        return try await query
            .order("created_at", ascending: false)
            .limit(200)
            .execute()
            .value
    }

    // MARK: - Platform Settings

    func fetchPlatformSettings() async throws -> [PlatformSetting] {
        try await client.from("platform_settings")
            .select()
            .order("key")
            .execute()
            .value
    }

    func updatePlatformSetting(key: String, value: String) async throws {
        try await client.rpc("admin_update_setting", params: [
            "p_key": AnyJSON.string(key),
            "p_value": AnyJSON.string(value),
        ]).execute()
    }
}
