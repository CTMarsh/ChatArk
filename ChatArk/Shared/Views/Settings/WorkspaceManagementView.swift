import SwiftUI

struct WorkspaceManagementView: View {
    @State private var viewModel = WorkspaceViewModel()
    @State private var showCreateWorkspace = false
    @State private var newWorkspaceName = ""
    @State private var showDeleteConfirm: Workspace?
    @State private var showEditName = false
    @State private var editingName = ""

    var body: some View {
        Form {
            workspaceListSection
            if viewModel.selectedWorkspace != nil {
                workspaceDetailSection
                membersSection
                widgetsSection
            }
        }
        .navigationTitle("Workspaces")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    newWorkspaceName = ""
                    showCreateWorkspace = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .alert("Create Workspace", isPresented: $showCreateWorkspace) {
            TextField("Workspace Name", text: $newWorkspaceName)
            Button("Create") {
                Task { await viewModel.createWorkspace(name: newWorkspaceName) }
            }
            .disabled(newWorkspaceName.trimmingCharacters(in: .whitespaces).isEmpty)
            Button("Cancel", role: .cancel) {}
        }
        .alert("Rename Workspace", isPresented: $showEditName) {
            TextField("Workspace Name", text: $editingName)
            Button("Save") {
                Task { await viewModel.updateWorkspaceName(editingName) }
            }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog(
            "Delete Workspace",
            isPresented: Binding(
                get: { showDeleteConfirm != nil },
                set: { if !$0 { showDeleteConfirm = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let workspace = showDeleteConfirm {
                    Task { await viewModel.deleteWorkspace(workspace) }
                }
            }
        } message: {
            Text("This will permanently delete the workspace and all its data. This action cannot be undone.")
        }
        .task {
            await viewModel.loadWorkspaces()
        }
    }

    // MARK: - Workspace List

    private var workspaceListSection: some View {
        Section("Your Workspaces") {
            if viewModel.isLoading {
                ProgressView()
            } else if viewModel.workspaces.isEmpty {
                Text("No workspaces yet")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.workspaces) { workspace in
                    Button {
                        Task { await viewModel.selectWorkspace(workspace) }
                    } label: {
                        HStack {
                            Image(systemName: "building.2")
                                .foregroundStyle(NauticalTheme.ocean)
                            Text(workspace.name)
                                .foregroundStyle(.primary)
                            Spacer()
                            if viewModel.selectedWorkspace?.id == workspace.id {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(NauticalTheme.ocean)
                            }
                        }
                    }
                }
            }

            if let error = viewModel.error {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.caption)
            }
        }
    }

    // MARK: - Workspace Detail

    @ViewBuilder
    private var workspaceDetailSection: some View {
        if let workspace = viewModel.selectedWorkspace {
            Section("Workspace Settings") {
                HStack {
                    Text("Name")
                    Spacer()
                    Text(workspace.name)
                        .foregroundStyle(.secondary)
                }

                Button("Rename Workspace") {
                    editingName = workspace.name
                    showEditName = true
                }

                Button(role: .destructive) {
                    showDeleteConfirm = workspace
                } label: {
                    Text("Delete Workspace")
                }
            }
        }
    }

    // MARK: - Widgets

    private var widgetsSection: some View {
        Section("Widgets (\(viewModel.widgets.count))") {
            NavigationLink {
                WidgetManagementView(viewModel: viewModel)
            } label: {
                Label("Manage Widgets", systemImage: "widget.small")
            }
        }
    }

    // MARK: - Members

    @ViewBuilder
    private var membersSection: some View {
        Section("Members (\(viewModel.members.count))") {
            ForEach(viewModel.members) { member in
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundStyle(.secondary)
                    VStack(alignment: .leading) {
                        Text(member.userId.uuidString.prefix(8) + "...")
                            .font(.body)
                        Text(member.role.rawValue.capitalized)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    #if !os(watchOS)
                    if member.role != .owner {
                        Menu {
                            ForEach(WorkspaceMemberRole.allCases.filter { $0 != .owner }, id: \.self) { role in
                                Button(role.rawValue.capitalized) {
                                    Task { await viewModel.updateMemberRole(userId: member.userId, role: role) }
                                }
                            }
                            Divider()
                            Button("Remove", role: .destructive) {
                                Task { await viewModel.removeMember(userId: member.userId) }
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundStyle(NauticalTheme.ocean)
                        }
                    }
                    #endif
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        WorkspaceManagementView()
    }
}
#endif
