import Foundation

@MainActor
@Observable
final class WorkspaceViewModel {
    var workspaces: [Workspace] = []
    var selectedWorkspace: Workspace?
    var members: [WorkspaceMember] = []
    var widgets: [WorkspaceWidget] = []
    var isLoading = false
    var error: String?

    private let workspaceService: WorkspaceService

    init(workspaceService: WorkspaceService = WorkspaceService()) {
        self.workspaceService = workspaceService
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
}
