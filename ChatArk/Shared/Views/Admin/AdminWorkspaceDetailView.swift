import SwiftUI
import Supabase

struct AdminWorkspaceDetailView: View {
    @Bindable var viewModel: AdminViewModel
    @State var workspace: Workspace
    @State private var showSuspendConfirm = false
    @State private var showDeleteConfirm = false
    @State private var showAddMember = false
    @State private var showCreateWidget = false
    @State private var removingMember: WorkspaceMember?
    @State private var isEditingName = false
    @State private var editedName = ""
    @State private var includeOwners = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            overviewSection
            settingsSection
            membersSection
            widgetsSection
            dangerSection
        }
        .navigationTitle(workspace.name)
        .confirmationDialog("Suspend / Activate Workspace", isPresented: $showSuspendConfirm, titleVisibility: .visible) {
            Button("Suspend", role: .destructive) {
                Task { await viewModel.suspendWorkspace(workspace, suspended: true) }
            }
            Button("Activate") {
                Task { await viewModel.suspendWorkspace(workspace, suspended: false) }
            }
        } message: {
            Text("Suspending will deactivate all widgets. Activating will restore the workspace.")
        }
        .confirmationDialog("Delete Workspace", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteWorkspace(workspace)
                    dismiss()
                }
            }
        } message: {
            Text("Permanently delete \"\(workspace.name)\" and all its widgets, members, and conversations? This cannot be undone.")
        }
        .confirmationDialog("Remove Member", isPresented: Binding(
            get: { removingMember != nil },
            set: { if !$0 { removingMember = nil } }
        ), titleVisibility: .visible) {
            Button("Remove", role: .destructive) {
                if let member = removingMember {
                    Task { await viewModel.removeWorkspaceMember(member) }
                }
            }
        } message: {
            Text("Remove this member from the workspace?")
        }
        .sheet(isPresented: $showAddMember) {
            AddMemberSheet(viewModel: viewModel, workspaceId: workspace.id)
        }
        .sheet(isPresented: $showCreateWidget) {
            CreateWidgetSheet(viewModel: viewModel, workspaceId: workspace.id)
        }
        .task {
            await viewModel.selectWorkspace(workspace)
            includeOwners = workspace.includeOwnersInAvailability ?? false
            editedName = workspace.name
        }
    }

    // MARK: - Overview

    private var overviewSection: some View {
        Section("Overview") {
            // Editable name
            if isEditingName {
                HStack {
                    TextField("Name", text: $editedName)
                    Button("Save") {
                        Task {
                            await viewModel.updateWorkspace(workspace, updates: [
                                "name": AnyJSON.string(editedName),
                            ])
                            workspace.name = editedName
                            isEditingName = false
                        }
                    }
                    .buttonStyle(.borderless)
                    Button("Cancel") {
                        editedName = workspace.name
                        isEditingName = false
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.secondary)
                }
            } else {
                HStack {
                    Text("Name")
                    Spacer()
                    Text(workspace.name)
                        .foregroundStyle(.secondary)
                    Button {
                        isEditingName = true
                    } label: {
                        Image(systemName: "pencil")
                            .arkType(.cap)
                    }
                    .buttonStyle(.borderless)
                }
            }

            HStack {
                Text("Members")
                Spacer()
                Text("\(viewModel.workspaceMembers.count)")
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text("Widgets")
                Spacer()
                Text("\(viewModel.workspaceWidgets.count)")
                    .foregroundStyle(.secondary)
            }
            if let createdAt = workspace.createdAt {
                HStack {
                    Text("Created")
                    Spacer()
                    Text(createdAt.formatted(date: .abbreviated, time: .omitted))
                        .foregroundStyle(.secondary)
                }
            }

            Toggle("Include Owners in Availability", isOn: $includeOwners)
                .onChange(of: includeOwners) {
                    Task {
                        await viewModel.updateWorkspace(workspace, updates: [
                            "include_owners_in_availability": AnyJSON.bool(includeOwners),
                        ])
                    }
                }

            Button(role: .destructive) {
                showSuspendConfirm = true
            } label: {
                Text("Suspend / Activate Workspace")
            }
        }
    }

    // MARK: - Settings

    private var settingsSection: some View {
        Section {
            NavigationLink {
                WorkspaceSettingsView(workspaceId: workspace.id)
            } label: {
                Label("Workspace Settings", systemImage: "gearshape")
            }
        }
    }

    // MARK: - Members

    private var membersSection: some View {
        Section {
            if viewModel.workspaceMembers.isEmpty {
                Text("No members")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.workspaceMembers) { member in
                    memberRow(member)
                }
            }
        } header: {
            HStack {
                Text("Members (\(viewModel.workspaceMembers.count))")
                Spacer()
                Button {
                    showAddMember = true
                } label: {
                    Label("Add", systemImage: "plus")
                        .arkType(.cap)
                }
            }
        }
    }

    private func memberRow(_ member: WorkspaceMember) -> some View {
        HStack {
            Image(systemName: memberIcon(member.role))
                .foregroundStyle(memberColor(member.role))

            Text(member.userId.uuidString.prefix(8) + "...")
                .arkType(.body)

            Spacer()

            // Role picker (editable)
            Picker("Role", selection: Binding(
                get: { member.role.rawValue },
                set: { newRole in
                    Task { await viewModel.updateMemberRole(member, newRole: newRole) }
                }
            )) {
                Text("Admin").tag("admin")
                Text("Agent").tag("agent")
                Text("Member").tag("member")
            }
            .labelsHidden()
            .frame(width: 100)

            // Remove button
            Button(role: .destructive) {
                removingMember = member
            } label: {
                Image(systemName: "person.badge.minus")
                    .foregroundStyle(.red)
            }
            .buttonStyle(.borderless)
        }
    }

    // MARK: - Widgets

    private var widgetsSection: some View {
        Section {
            if viewModel.workspaceWidgets.isEmpty {
                Text("No widgets")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.workspaceWidgets) { widget in
                    NavigationLink {
                        WidgetDetailView(widget: widget, workspaceId: workspace.id)
                    } label: {
                        widgetRow(widget)
                    }
                }
            }
        } header: {
            HStack {
                Text("Widgets (\(viewModel.workspaceWidgets.count))")
                Spacer()
                Button {
                    showCreateWidget = true
                } label: {
                    Label("Create", systemImage: "plus")
                        .arkType(.cap)
                }
            }
        }
    }

    private func widgetRow(_ widget: WorkspaceWidget) -> some View {
        HStack {
            Image(systemName: "widget.small")
                .foregroundStyle(.indigo)
            VStack(alignment: .leading) {
                Text(widget.name)
                    .arkType(.body)
                if let createdAt = widget.createdAt {
                    Text(createdAt.formatted(date: .abbreviated, time: .omitted))
                        .arkType(.cap)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text(widget.isActive == true ? "Active" : "Inactive")
                .arkType(.cap)
                .foregroundStyle(widget.isActive == true ? .green : .secondary)
        }
    }

    // MARK: - Danger Zone

    private var dangerSection: some View {
        Section {
            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                Label("Delete Workspace", systemImage: "trash")
            }
        } header: {
            Text("Danger Zone")
                .foregroundStyle(.red)
        }
    }

    // MARK: - Helpers

    private func memberIcon(_ role: WorkspaceMemberRole) -> String {
        switch role {
        case .owner: "crown.fill"
        case .admin: "shield.fill"
        case .agent: "person.fill"
        case .member: "eye.fill"
        }
    }

    private func memberColor(_ role: WorkspaceMemberRole) -> Color {
        switch role {
        case .owner: .yellow
        case .admin: .blue
        case .agent: .green
        case .member: .secondary
        }
    }
}

// MARK: - Add Member Sheet

struct AddMemberSheet: View {
    @Bindable var viewModel: AdminViewModel
    let workspaceId: UUID
    @Environment(\.dismiss) private var dismiss
    @State private var allUsers: [Profile] = []
    @State private var selectedUserId: UUID?
    @State private var selectedRole = "agent"
    @State private var isAdding = false

    private let adminService = AdminService()

    var body: some View {
        NavigationStack {
            Form {
                Section("User") {
                    if allUsers.isEmpty {
                        ProgressView()
                    } else {
                        Picker("User", selection: $selectedUserId) {
                            Text("Select a user").tag(nil as UUID?)
                            ForEach(availableUsers) { user in
                                Text("\(user.displayLabel) (\(user.email ?? user.username ?? ""))")
                                    .tag(user.id as UUID?)
                            }
                        }
                    }
                }

                Section("Role") {
                    Picker("Role", selection: $selectedRole) {
                        Text("Admin").tag("admin")
                        Text("Agent").tag("agent")
                        Text("Member").tag("member")
                    }
                    #if !os(watchOS)
                    .pickerStyle(.segmented)
                    #endif
                }
            }
            .navigationTitle("Add Member")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task { await addMember() }
                    }
                    .disabled(selectedUserId == nil || isAdding)
                }
            }
            .task {
                do {
                    allUsers = try await adminService.fetchAllUsers()
                } catch {
                    viewModel.error = ErrorSanitizer.sanitize(error)
                }
            }
        }
    }

    private var availableUsers: [Profile] {
        let existingIds = Set(viewModel.workspaceMembers.map(\.userId))
        return allUsers.filter { !existingIds.contains($0.id) }
    }

    private func addMember() async {
        guard let userId = selectedUserId else { return }
        isAdding = true
        defer { isAdding = false }
        await viewModel.addWorkspaceMember(workspaceId: workspaceId, userId: userId, role: selectedRole)
        dismiss()
    }
}

// MARK: - Create Widget Sheet

struct CreateWidgetSheet: View {
    @Bindable var viewModel: AdminViewModel
    let workspaceId: UUID
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var isCreating = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Widget Name", text: $name)
                }

                if let error = viewModel.error {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .arkType(.cap)
                    }
                }
            }
            .navigationTitle("Create Widget")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task { await createWidget() }
                    }
                    .disabled(name.isEmpty || isCreating)
                }
            }
        }
    }

    private func createWidget() async {
        isCreating = true
        defer { isCreating = false }
        if await viewModel.createWidget(workspaceId: workspaceId, name: name) != nil {
            dismiss()
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        AdminWorkspaceDetailView(
            viewModel: AdminViewModel(),
            workspace: Workspace(id: UUID(), name: "Test Workspace", ownerId: UUID())
        )
    }
}
#endif
