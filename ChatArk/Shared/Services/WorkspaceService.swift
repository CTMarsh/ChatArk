import Foundation
import Supabase

@MainActor
final class WorkspaceService {
    private let client: SupabaseClient

    nonisolated init(client: SupabaseClient = supabaseClient) {
        self.client = client
    }

    // MARK: - Workspaces

    func fetchWorkspaces() async throws -> [Workspace] {
        guard let userId = client.auth.currentUser?.id else {
            throw ChatError.notAuthenticated
        }

        let memberships: [WorkspaceMember] = try await client
            .from("workspace_members")
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value

        let workspaceIds = memberships.map(\.workspaceId.uuidString)
        guard !workspaceIds.isEmpty else { return [] }

        return try await client.from("workspaces")
            .select()
            .in("id", values: workspaceIds)
            .order("name")
            .execute()
            .value
    }

    func createWorkspace(name: String) async throws -> Workspace {
        guard let userId = client.auth.currentUser?.id else {
            throw ChatError.notAuthenticated
        }

        let workspace: Workspace = try await client.from("workspaces")
            .insert([
                "name": AnyJSON.string(name),
                "owner_id": AnyJSON.string(userId.uuidString),
            ])
            .select()
            .single()
            .execute()
            .value

        // Add owner as workspace member
        try await client.from("workspace_members")
            .insert([
                "workspace_id": AnyJSON.string(workspace.id.uuidString),
                "user_id": AnyJSON.string(userId.uuidString),
                "role": AnyJSON.string("owner"),
            ])
            .execute()

        return workspace
    }

    func updateWorkspace(id: UUID, name: String) async throws {
        try await client.from("workspaces")
            .update(["name": AnyJSON.string(name)])
            .eq("id", value: id.uuidString)
            .execute()
    }

    func deleteWorkspace(id: UUID) async throws {
        try await client.from("workspaces")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - Members

    func fetchMembers(workspaceId: UUID) async throws -> [WorkspaceMember] {
        try await client.from("workspace_members")
            .select()
            .eq("workspace_id", value: workspaceId.uuidString)
            .execute()
            .value
    }

    func addMember(workspaceId: UUID, userId: UUID, role: WorkspaceMemberRole = .agent) async throws {
        try await client.from("workspace_members")
            .insert([
                "workspace_id": AnyJSON.string(workspaceId.uuidString),
                "user_id": AnyJSON.string(userId.uuidString),
                "role": AnyJSON.string(role.rawValue),
            ])
            .execute()
    }

    func updateMemberRole(workspaceId: UUID, userId: UUID, role: WorkspaceMemberRole) async throws {
        try await client.from("workspace_members")
            .update(["role": AnyJSON.string(role.rawValue)])
            .eq("workspace_id", value: workspaceId.uuidString)
            .eq("user_id", value: userId.uuidString)
            .execute()
    }

    func removeMember(workspaceId: UUID, userId: UUID) async throws {
        try await client.from("workspace_members")
            .delete()
            .eq("workspace_id", value: workspaceId.uuidString)
            .eq("user_id", value: userId.uuidString)
            .execute()
    }

    // MARK: - Widgets

    func fetchWidgets(workspaceId: UUID) async throws -> [WorkspaceWidget] {
        try await client.from("widgets")
            .select()
            .eq("workspace_id", value: workspaceId.uuidString)
            .execute()
            .value
    }

    func createWidget(workspaceId: UUID, name: String) async throws -> WorkspaceWidget {
        try await client.from("widgets")
            .insert([
                "workspace_id": AnyJSON.string(workspaceId.uuidString),
                "name": AnyJSON.string(name),
            ])
            .select()
            .single()
            .execute()
            .value
    }

    func updateWidget(id: UUID, updates: [String: AnyJSON]) async throws {
        try await client.from("widgets")
            .update(updates)
            .eq("id", value: id.uuidString)
            .execute()
    }

    func deleteWidget(id: UUID) async throws {
        try await client.from("widgets")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    func regenerateWidgetToken(id: UUID) async throws -> String {
        try await client.rpc("regenerate_widget_token", params: ["p_widget_id": AnyJSON.string(id.uuidString)])
            .execute()
            .value
    }
}
