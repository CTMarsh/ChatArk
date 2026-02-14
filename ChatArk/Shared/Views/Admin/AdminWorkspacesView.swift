import SwiftUI

struct AdminWorkspacesView: View {
    @Bindable var viewModel: AdminViewModel

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

#if DEBUG
#Preview {
    NavigationStack {
        AdminWorkspacesView(viewModel: AdminViewModel())
    }
}
#endif
