import SwiftUI
import Supabase

struct AdminWorkspacesView: View {
    @Bindable var viewModel: AdminViewModel
    @State private var showCreateWorkspace = false

    var body: some View {
        List {
            Section {
                TextField("Search workspaces...", text: $viewModel.workspaceSearch)
                    #if os(iOS) || os(visionOS)
                    .textInputAutocapitalization(.never)
                    #endif
                    .autocorrectionDisabled()
                    .onSubmit {
                        Task { await viewModel.loadWorkspaces() }
                    }
            }

            Section {
                if viewModel.isLoading {
                    ProgressView()
                } else if viewModel.workspaces.isEmpty {
                    Text("No workspaces found")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.workspaces) { workspace in
                        NavigationLink {
                            AdminWorkspaceDetailView(viewModel: viewModel, workspace: workspace)
                        } label: {
                            workspaceRow(workspace)
                        }
                    }
                }
            }

            if let error = viewModel.error {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }
        }
        .navigationTitle("Workspaces")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showCreateWorkspace = true
                } label: {
                    Label("Create Workspace", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showCreateWorkspace) {
            CreateWorkspaceSheet(viewModel: viewModel)
        }
        .task {
            await viewModel.loadWorkspaces()
        }
    }

    private func workspaceRow(_ workspace: Workspace) -> some View {
        HStack {
            Image(systemName: "building.2")
                .foregroundStyle(.red.opacity(0.8))
                .frame(width: 32, height: 32)
                .background(.red.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 2) {
                Text(workspace.name)
                    .font(.body)
                    .fontWeight(.medium)
                if let createdAt = workspace.createdAt {
                    Text("Created \(createdAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

// MARK: - Create Workspace Sheet

struct CreateWorkspaceSheet: View {
    @Bindable var viewModel: AdminViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var selectedOwnerId: UUID?
    @State private var allUsers: [Profile] = []
    @State private var isCreating = false

    private let adminService = AdminService()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Workspace Name", text: $name)
                }

                Section("Owner") {
                    if allUsers.isEmpty {
                        ProgressView()
                    } else {
                        Picker("Owner", selection: $selectedOwnerId) {
                            Text("Select a user").tag(nil as UUID?)
                            ForEach(allUsers) { user in
                                Text("\(user.displayLabel) (\(user.email ?? user.username ?? ""))")
                                    .tag(user.id as UUID?)
                            }
                        }
                    }
                }

                if let error = viewModel.error {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Create Workspace")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task { await createWorkspace() }
                    }
                    .disabled(name.isEmpty || selectedOwnerId == nil || isCreating)
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

    private func createWorkspace() async {
        guard let ownerId = selectedOwnerId else { return }
        isCreating = true
        defer { isCreating = false }
        if await viewModel.createWorkspace(name: name, ownerId: ownerId) != nil {
            dismiss()
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        AdminWorkspacesView(viewModel: AdminViewModel())
    }
}
#endif
