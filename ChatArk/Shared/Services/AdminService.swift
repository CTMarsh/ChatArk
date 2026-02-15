import Foundation
import Supabase

struct AdminCreateUserResponse: Codable, Sendable {
    var id: String
    var generatedPassword: String
}

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

    func createUser(email: String, name: String?, sendConfirmationEmail: Bool) async throws -> AdminCreateUserResponse {
        try await client.functions.invoke(
            "admin-create-user",
            options: .init(body: [
                "email": AnyJSON.string(email),
                "name": name.map { AnyJSON.string($0) } ?? .null,
                "sendConfirmationEmail": AnyJSON.bool(sendConfirmationEmail),
            ])
        )
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

    func createWorkspace(name: String, ownerId: UUID) async throws -> Workspace {
        let workspace: Workspace = try await client.from("workspaces")
            .insert([
                "name": AnyJSON.string(name),
                "owner_id": AnyJSON.string(ownerId.uuidString),
            ])
            .select()
            .single()
            .execute()
            .value

        try await client.rpc("admin_log_action", params: [
            "p_action": AnyJSON.string("workspace_created"),
            "p_target_type": AnyJSON.string("workspace"),
            "p_target_id": AnyJSON.string(workspace.id.uuidString),
        ]).execute()

        return workspace
    }

    func updateWorkspace(id: UUID, updates: [String: AnyJSON]) async throws {
        try await client.from("workspaces")
            .update(updates)
            .eq("id", value: id.uuidString)
            .execute()

        try await client.rpc("admin_log_action", params: [
            "p_action": AnyJSON.string("workspace_updated"),
            "p_target_type": AnyJSON.string("workspace"),
            "p_target_id": AnyJSON.string(id.uuidString),
        ]).execute()
    }

    func deleteWorkspace(id: UUID) async throws {
        try await client.from("workspaces")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()

        try await client.rpc("admin_log_action", params: [
            "p_action": AnyJSON.string("workspace_deleted"),
            "p_target_type": AnyJSON.string("workspace"),
            "p_target_id": AnyJSON.string(id.uuidString),
        ]).execute()
    }

    func suspendWorkspace(id: UUID, suspended: Bool) async throws {
        try await client.rpc("admin_set_workspace_suspended", params: [
            "p_workspace_id": AnyJSON.string(id.uuidString),
            "p_suspended": AnyJSON.bool(suspended),
        ]).execute()
    }

    func fetchWorkspaceMembers(workspaceId: UUID) async throws -> [WorkspaceMember] {
        try await client.from("workspace_members")
            .select()
            .eq("workspace_id", value: workspaceId.uuidString)
            .execute()
            .value
    }

    func addWorkspaceMember(workspaceId: UUID, userId: UUID, role: String) async throws {
        try await client.from("workspace_members")
            .insert([
                "workspace_id": AnyJSON.string(workspaceId.uuidString),
                "user_id": AnyJSON.string(userId.uuidString),
                "role": AnyJSON.string(role),
            ])
            .execute()

        try await client.rpc("admin_log_action", params: [
            "p_action": AnyJSON.string("workspace_member_added"),
            "p_target_type": AnyJSON.string("workspace"),
            "p_target_id": AnyJSON.string(workspaceId.uuidString),
        ]).execute()
    }

    func removeWorkspaceMember(memberId: UUID, workspaceId: UUID) async throws {
        try await client.from("workspace_members")
            .delete()
            .eq("id", value: memberId.uuidString)
            .execute()

        try await client.rpc("admin_log_action", params: [
            "p_action": AnyJSON.string("workspace_member_removed"),
            "p_target_type": AnyJSON.string("workspace"),
            "p_target_id": AnyJSON.string(workspaceId.uuidString),
        ]).execute()
    }

    func updateMemberRole(memberId: UUID, role: String, workspaceId: UUID) async throws {
        try await client.from("workspace_members")
            .update(["role": AnyJSON.string(role)])
            .eq("id", value: memberId.uuidString)
            .execute()

        try await client.rpc("admin_log_action", params: [
            "p_action": AnyJSON.string("workspace_member_role_changed"),
            "p_target_type": AnyJSON.string("workspace"),
            "p_target_id": AnyJSON.string(workspaceId.uuidString),
        ]).execute()
    }

    func fetchWorkspaceWidgets(workspaceId: UUID) async throws -> [WorkspaceWidget] {
        try await client.from("widgets")
            .select()
            .eq("workspace_id", value: workspaceId.uuidString)
            .execute()
            .value
    }

    func createWidget(workspaceId: UUID, name: String) async throws -> WorkspaceWidget {
        let widget: WorkspaceWidget = try await client.from("widgets")
            .insert([
                "workspace_id": AnyJSON.string(workspaceId.uuidString),
                "name": AnyJSON.string(name),
            ])
            .select()
            .single()
            .execute()
            .value

        try await client.rpc("admin_log_action", params: [
            "p_action": AnyJSON.string("widget_created"),
            "p_target_type": AnyJSON.string("widget"),
            "p_target_id": AnyJSON.string(widget.id.uuidString),
        ]).execute()

        return widget
    }

    func deleteWidget(id: UUID) async throws {
        try await client.from("widgets")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()

        try await client.rpc("admin_log_action", params: [
            "p_action": AnyJSON.string("widget_deleted"),
            "p_target_type": AnyJSON.string("widget"),
            "p_target_id": AnyJSON.string(id.uuidString),
        ]).execute()
    }

    func regenerateWidgetToken(id: UUID) async throws {
        try await client.rpc("admin_regenerate_widget_token", params: [
            "p_widget_id": AnyJSON.string(id.uuidString),
        ]).execute()
    }

    // MARK: - Audit Log

    func fetchAuditLogs(action: String? = nil) async throws -> [AdminAuditLog] {
        var query = client.from("admin_audit_logs")
            .select("id, admin_id, action, target_type, target_id, metadata, created_at, profiles!admin_audit_logs_admin_id_fkey(display_name, username)")

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
