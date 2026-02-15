import Foundation
import Supabase

@MainActor
@Observable
final class AdminViewModel {
    var metrics: DashboardMetrics?
    var users: [Profile] = []
    var selectedUser: Profile?
    var userWorkspaces: [Workspace] = []
    var userMemberships: [WorkspaceMember] = []
    var workspaces: [Workspace] = []
    var selectedWorkspace: Workspace?
    var workspaceMembers: [WorkspaceMember] = []
    var workspaceWidgets: [WorkspaceWidget] = []
    var auditLogs: [AdminAuditLog] = []
    var platformSettings: [PlatformSetting] = []
    var isLoading = false
    var error: String?
    var userSearch = ""
    var workspaceSearch = ""
    var auditFilter = ""

    private let adminService: AdminService

    var currentUserId: UUID? {
        SupabaseManager.shared.client.auth.currentUser?.id
    }

    init(adminService: AdminService = AdminService()) {
        self.adminService = adminService
    }

    // MARK: - Dashboard

    func loadDashboard() async {
        isLoading = true
        defer { isLoading = false }
        do {
            metrics = try await adminService.getDashboardMetrics()
        } catch {
            self.error = ErrorSanitizer.sanitize(error)
        }
    }

    // MARK: - Users

    func loadUsers() async {
        isLoading = true
        defer { isLoading = false }
        do {
            users = try await adminService.fetchAllUsers(search: userSearch.isEmpty ? nil : userSearch)
        } catch {
            self.error = ErrorSanitizer.sanitize(error)
        }
    }

    func selectUser(_ user: Profile) async {
        selectedUser = user
        do {
            userWorkspaces = try await adminService.fetchUserWorkspaces(userId: user.id)
            userMemberships = try await adminService.fetchUserMemberships(userId: user.id)
        } catch {
            self.error = ErrorSanitizer.sanitize(error)
        }
    }

    func createUser(email: String, name: String?, sendConfirmationEmail: Bool) async -> AdminCreateUserResponse? {
        do {
            let result = try await adminService.createUser(
                email: email,
                name: name,
                sendConfirmationEmail: sendConfirmationEmail
            )
            await loadUsers()
            return result
        } catch {
            self.error = ErrorSanitizer.sanitize(error)
            return nil
        }
    }

    func suspendUser(_ user: Profile) async {
        do {
            let isSuspended = user.status == .suspended
            try await adminService.suspendUser(id: user.id, suspended: !isSuspended)
            if let index = users.firstIndex(where: { $0.id == user.id }) {
                users[index].status = isSuspended ? .offline : .suspended
            }
            selectedUser?.status = isSuspended ? .offline : .suspended
        } catch {
            self.error = ErrorSanitizer.sanitize(error)
        }
    }

    func deleteUser(_ user: Profile) async {
        do {
            try await adminService.deleteUser(id: user.id)
            users.removeAll { $0.id == user.id }
            selectedUser = nil
        } catch {
            self.error = ErrorSanitizer.sanitize(error)
        }
    }

    func resetUserMFA(_ user: Profile) async {
        do {
            try await adminService.resetUserMFA(id: user.id)
        } catch {
            self.error = ErrorSanitizer.sanitize(error)
        }
    }

    func toggleUserAdmin(_ user: Profile) async {
        do {
            let newValue = !(user.isPlatformAdmin ?? false)
            try await adminService.setUserAdmin(id: user.id, isAdmin: newValue)
            if let index = users.firstIndex(where: { $0.id == user.id }) {
                users[index].isPlatformAdmin = newValue
            }
            selectedUser?.isPlatformAdmin = newValue
        } catch {
            self.error = ErrorSanitizer.sanitize(error)
        }
    }

    // MARK: - Workspaces

    func loadWorkspaces() async {
        isLoading = true
        defer { isLoading = false }
        do {
            workspaces = try await adminService.fetchAllWorkspaces(search: workspaceSearch.isEmpty ? nil : workspaceSearch)
        } catch {
            self.error = ErrorSanitizer.sanitize(error)
        }
    }

    func selectWorkspace(_ workspace: Workspace) async {
        selectedWorkspace = workspace
        do {
            workspaceMembers = try await adminService.fetchWorkspaceMembers(workspaceId: workspace.id)
            workspaceWidgets = try await adminService.fetchWorkspaceWidgets(workspaceId: workspace.id)
        } catch {
            self.error = ErrorSanitizer.sanitize(error)
        }
    }

    func createWorkspace(name: String, ownerId: UUID) async -> Workspace? {
        do {
            let workspace = try await adminService.createWorkspace(name: name, ownerId: ownerId)
            await loadWorkspaces()
            return workspace
        } catch {
            self.error = ErrorSanitizer.sanitize(error)
            return nil
        }
    }

    func updateWorkspace(_ workspace: Workspace, updates: [String: AnyJSON]) async {
        do {
            try await adminService.updateWorkspace(id: workspace.id, updates: updates)
            if let index = workspaces.firstIndex(where: { $0.id == workspace.id }) {
                if let name = updates["name"]?.stringValue {
                    workspaces[index].name = name
                }
            }
        } catch {
            self.error = ErrorSanitizer.sanitize(error)
        }
    }

    func deleteWorkspace(_ workspace: Workspace) async {
        do {
            try await adminService.deleteWorkspace(id: workspace.id)
            workspaces.removeAll { $0.id == workspace.id }
        } catch {
            self.error = ErrorSanitizer.sanitize(error)
        }
    }

    func suspendWorkspace(_ workspace: Workspace, suspended: Bool) async {
        do {
            try await adminService.suspendWorkspace(id: workspace.id, suspended: suspended)
            await loadWorkspaces()
        } catch {
            self.error = ErrorSanitizer.sanitize(error)
        }
    }

    // MARK: - Members

    func addWorkspaceMember(workspaceId: UUID, userId: UUID, role: String) async {
        do {
            try await adminService.addWorkspaceMember(workspaceId: workspaceId, userId: userId, role: role)
            workspaceMembers = try await adminService.fetchWorkspaceMembers(workspaceId: workspaceId)
        } catch {
            self.error = ErrorSanitizer.sanitize(error)
        }
    }

    func removeWorkspaceMember(_ member: WorkspaceMember) async {
        do {
            try await adminService.removeWorkspaceMember(memberId: member.id, workspaceId: member.workspaceId)
            workspaceMembers.removeAll { $0.id == member.id }
        } catch {
            self.error = ErrorSanitizer.sanitize(error)
        }
    }

    func updateMemberRole(_ member: WorkspaceMember, newRole: String) async {
        do {
            try await adminService.updateMemberRole(memberId: member.id, role: newRole, workspaceId: member.workspaceId)
            if let index = workspaceMembers.firstIndex(where: { $0.id == member.id }) {
                workspaceMembers[index].role = WorkspaceMemberRole(rawValue: newRole) ?? member.role
            }
        } catch {
            self.error = ErrorSanitizer.sanitize(error)
        }
    }

    // MARK: - Widgets

    func createWidget(workspaceId: UUID, name: String) async -> WorkspaceWidget? {
        do {
            let widget = try await adminService.createWidget(workspaceId: workspaceId, name: name)
            workspaceWidgets.append(widget)
            return widget
        } catch {
            self.error = ErrorSanitizer.sanitize(error)
            return nil
        }
    }

    func deleteWidget(_ widget: WorkspaceWidget) async {
        do {
            try await adminService.deleteWidget(id: widget.id)
            workspaceWidgets.removeAll { $0.id == widget.id }
        } catch {
            self.error = ErrorSanitizer.sanitize(error)
        }
    }

    func regenerateWidgetToken(_ widget: WorkspaceWidget) async {
        do {
            try await adminService.regenerateWidgetToken(id: widget.id)
            // Reload widgets to get new token
            if let wsId = selectedWorkspace?.id {
                workspaceWidgets = try await adminService.fetchWorkspaceWidgets(workspaceId: wsId)
            }
        } catch {
            self.error = ErrorSanitizer.sanitize(error)
        }
    }

    // MARK: - Audit Log

    func loadAuditLogs() async {
        isLoading = true
        defer { isLoading = false }
        do {
            auditLogs = try await adminService.fetchAuditLogs(action: auditFilter.isEmpty ? nil : auditFilter)
        } catch {
            self.error = ErrorSanitizer.sanitize(error)
        }
    }

    // MARK: - Platform Settings

    func loadPlatformSettings() async {
        isLoading = true
        defer { isLoading = false }
        do {
            platformSettings = try await adminService.fetchPlatformSettings()
        } catch {
            self.error = ErrorSanitizer.sanitize(error)
        }
    }

    func updateSetting(key: String, value: String) async {
        do {
            try await adminService.updatePlatformSetting(key: key, value: value)
            if let index = platformSettings.firstIndex(where: { $0.key == key }) {
                platformSettings[index].value = value
            }
        } catch {
            self.error = ErrorSanitizer.sanitize(error)
        }
    }
}
