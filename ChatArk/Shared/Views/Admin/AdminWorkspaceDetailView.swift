import SwiftUI

struct AdminWorkspaceDetailView: View {
    @Bindable var viewModel: AdminViewModel
    let workspace: Workspace
    @State private var showSuspendConfirm = false

    var body: some View {
        List {
            overviewSection
            settingsSection
            membersSection
            widgetsSection
        }
        .navigationTitle(workspace.name)
        .confirmationDialog("Suspend Workspace", isPresented: $showSuspendConfirm, titleVisibility: .visible) {
            Button("Suspend", role: .destructive) {
                Task { await viewModel.suspendWorkspace(workspace, suspended: true) }
            }
        } message: {
            Text("This will deactivate all widgets in this workspace.")
        }
        .task {
            await viewModel.selectWorkspace(workspace)
        }
    }

    // MARK: - Overview

    private var overviewSection: some View {
        Section("Overview") {
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
            HStack {
                Text("Include Owners in Availability")
                Spacer()
                Text(workspace.includeOwnersInAvailability == true ? "Yes" : "No")
                    .foregroundStyle(.secondary)
            }

            Button(role: .destructive) {
                showSuspendConfirm = true
            } label: {
                Text("Suspend Workspace")
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
        Section("Members (\(viewModel.workspaceMembers.count))") {
            if viewModel.workspaceMembers.isEmpty {
                Text("No members")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.workspaceMembers) { member in
                    HStack {
                        Image(systemName: memberIcon(member.role))
                            .foregroundStyle(memberColor(member.role))
                        Text(member.userId.uuidString.prefix(8) + "...")
                            .font(.body)
                        Spacer()
                        Text(member.role.rawValue.capitalized)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(memberColor(member.role).opacity(0.1))
                            .foregroundStyle(memberColor(member.role))
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    // MARK: - Widgets

    private var widgetsSection: some View {
        Section("Widgets (\(viewModel.workspaceWidgets.count))") {
            if viewModel.workspaceWidgets.isEmpty {
                Text("No widgets")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.workspaceWidgets) { widget in
                    HStack {
                        Image(systemName: "widget.small")
                            .foregroundStyle(.indigo)
                        VStack(alignment: .leading) {
                            Text(widget.name)
                                .font(.body)
                            if let createdAt = widget.createdAt {
                                Text(createdAt.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Text(widget.isActive == true ? "Active" : "Inactive")
                            .font(.caption)
                            .foregroundStyle(widget.isActive == true ? .green : .secondary)
                    }
                }
            }
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
