import Foundation

@MainActor
@Observable
final class WorkspaceViewModel {
    var workspaces: [Workspace] = []
    var selectedWorkspace: Workspace?
    var members: [WorkspaceMember] = []
    var memberProfiles: [UUID: Profile] = [:]
    var widgets: [WorkspaceWidget] = []
    var isLoading = false
    var error: String?

    private let workspaceService: WorkspaceService
    private let presenceService: PresenceService

    init(workspaceService: WorkspaceService = WorkspaceService(), presenceService: PresenceService = PresenceService()) {
        self.workspaceService = workspaceService
        self.presenceService = presenceService
    }

    func loadWorkspaces() async {
        isLoading = true
        defer { isLoading = false }

        do {
            workspaces = try await workspaceService.fetchWorkspaces()
            if selectedWorkspace == nil {
                selectedWorkspace = workspaces.first
            }
        } catch {
            self.error = ErrorSanitizer.sanitize(error)
        }
    }

    func selectWorkspace(_ workspace: Workspace) async {
        selectedWorkspace = workspace
        await loadWorkspaceDetails()
    }

    func loadWorkspaceDetails() async {
        guard let workspace = selectedWorkspace else { return }

        do {
            members = try await workspaceService.fetchMembers(workspaceId: workspace.id)
            widgets = try await workspaceService.fetchWidgets(workspaceId: workspace.id)

            let userIds = members.map(\.userId)
            let profiles = try await presenceService.fetchProfiles(userIds: userIds)
            memberProfiles = Dictionary(uniqueKeysWithValues: profiles.map { ($0.id, $0) })
        } catch {
            self.error = ErrorSanitizer.sanitize(error)
        }
    }

    func createWorkspace(name: String) async {
        do {
            let workspace = try await workspaceService.createWorkspace(name: name)
            workspaces.append(workspace)
            selectedWorkspace = workspace
        } catch {
            self.error = ErrorSanitizer.sanitize(error)
        }
    }

    func deleteWorkspace(_ workspace: Workspace) async {
        do {
            try await workspaceService.deleteWorkspace(id: workspace.id)
            workspaces.removeAll { $0.id == workspace.id }
            if selectedWorkspace?.id == workspace.id {
                selectedWorkspace = workspaces.first
            }
        } catch {
            self.error = ErrorSanitizer.sanitize(error)
        }
    }

    func addMember(userId: UUID) async {
        guard let workspace = selectedWorkspace else { return }
        do {
            try await workspaceService.addMember(workspaceId: workspace.id, userId: userId)
            await loadWorkspaceDetails()
        } catch {
            self.error = ErrorSanitizer.sanitize(error)
        }
    }

    func removeMember(userId: UUID) async {
        guard let workspace = selectedWorkspace else { return }
        do {
            try await workspaceService.removeMember(workspaceId: workspace.id, userId: userId)
            members.removeAll { $0.userId == userId }
        } catch {
            self.error = ErrorSanitizer.sanitize(error)
        }
    }

    func updateMemberRole(userId: UUID, role: WorkspaceMemberRole) async {
        guard let workspace = selectedWorkspace else { return }
        do {
            try await workspaceService.updateMemberRole(workspaceId: workspace.id, userId: userId, role: role)
            if let index = members.firstIndex(where: { $0.userId == userId }) {
                members[index].role = role
            }
        } catch {
            self.error = ErrorSanitizer.sanitize(error)
        }
    }

    func updateWorkspaceName(_ name: String) async {
        guard let workspace = selectedWorkspace else { return }
        do {
            try await workspaceService.updateWorkspace(id: workspace.id, name: name)
            if let index = workspaces.firstIndex(where: { $0.id == workspace.id }) {
                workspaces[index].name = name
            }
            selectedWorkspace?.name = name
        } catch {
            self.error = ErrorSanitizer.sanitize(error)
        }
    }

    func createWidget(name: String) async {
        guard let workspace = selectedWorkspace else { return }
        do {
            let widget = try await workspaceService.createWidget(workspaceId: workspace.id, name: name)
            widgets.append(widget)
        } catch {
            self.error = ErrorSanitizer.sanitize(error)
        }
    }

    func deleteWidget(_ widget: WorkspaceWidget) async {
        do {
            try await workspaceService.deleteWidget(id: widget.id)
            widgets.removeAll { $0.id == widget.id }
        } catch {
            self.error = ErrorSanitizer.sanitize(error)
        }
    }

    func regenerateWidgetToken(_ widget: WorkspaceWidget) async -> String? {
        do {
            let newToken = try await workspaceService.regenerateWidgetToken(id: widget.id)
            if let index = widgets.firstIndex(where: { $0.id == widget.id }) {
                widgets[index].embedToken = newToken
            }
            return newToken
        } catch {
            self.error = ErrorSanitizer.sanitize(error)
            return nil
        }
    }
}
