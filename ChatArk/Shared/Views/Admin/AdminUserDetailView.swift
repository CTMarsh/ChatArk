import SwiftUI
import Supabase

struct AdminUserDetailView: View {
    @Bindable var viewModel: AdminViewModel
    @State var user: Profile
    @State private var showSuspendConfirm = false
    @State private var showDeleteConfirm = false
    @State private var showResetMFAConfirm = false
    @State private var showAdminConfirm = false
    @Environment(\.dismiss) private var dismiss

    private var isSelf: Bool {
        viewModel.currentUserId == user.id
    }

    var body: some View {
        List {
            headerSection
            actionsSection
            profileSection
            if !viewModel.userWorkspaces.isEmpty {
                ownedWorkspacesSection
            }
            if !viewModel.userMemberships.isEmpty {
                membershipsSection
            }
            if !isSelf {
                dangerSection
            }
        }
        .navigationTitle(user.displayLabel)
        .confirmationDialog(
            user.status == .suspended ? "Activate User" : "Suspend User",
            isPresented: $showSuspendConfirm,
            titleVisibility: .visible
        ) {
            Button(user.status == .suspended ? "Activate" : "Suspend", role: .destructive) {
                Task {
                    await viewModel.suspendUser(user)
                    user = viewModel.selectedUser ?? user
                }
            }
        } message: {
            Text(user.status == .suspended
                ? "Activate this user? They will be able to log in again."
                : "Suspend this user? They will not be able to log in.")
        }
        .confirmationDialog("Delete User", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteUser(user)
                    dismiss()
                }
            }
        } message: {
            Text("This will permanently delete this user and all their data. This action cannot be undone.")
        }
        .confirmationDialog("Reset MFA", isPresented: $showResetMFAConfirm, titleVisibility: .visible) {
            Button("Reset MFA", role: .destructive) {
                Task { await viewModel.resetUserMFA(user) }
            }
        } message: {
            Text("This will remove all MFA factors for \(user.displayLabel). They will need to set up MFA again on their next login.")
        }
        .confirmationDialog(
            user.isPlatformAdmin == true ? "Revoke Admin" : "Grant Admin",
            isPresented: $showAdminConfirm,
            titleVisibility: .visible
        ) {
            Button(user.isPlatformAdmin == true ? "Revoke Admin" : "Grant Admin", role: .destructive) {
                Task {
                    await viewModel.toggleUserAdmin(user)
                    user = viewModel.selectedUser ?? user
                }
            }
        } message: {
            Text(user.isPlatformAdmin == true
                ? "Revoke platform admin privileges from \(user.displayLabel)?"
                : "Grant platform admin privileges to \(user.displayLabel)?")
        }
        .task {
            await viewModel.selectUser(user)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        Section {
            HStack {
                AvatarView(
                    url: user.avatarUrl,
                    name: user.displayLabel,
                    size: 56
                )

                VStack(alignment: .leading, spacing: ConstellationSpacing.s1) {
                    HStack(spacing: ConstellationSpacing.s1) {
                        Text(user.displayLabel)
                            .arkType(.lead)
                            .fontWeight(.bold)
                        if user.isPlatformAdmin == true {
                            Text("Admin")
                                .arkType(.cap)
                                .padding(.horizontal, ConstellationSpacing.s1)
                                .padding(.vertical, ConstellationSpacing.s1)
                                .background(.red.opacity(0.2))
                                .foregroundStyle(.red)
                                .clipShape(Capsule())
                        }
                        if user.status == .suspended {
                            Text("Suspended")
                                .arkType(.cap)
                                .padding(.horizontal, ConstellationSpacing.s1)
                                .padding(.vertical, ConstellationSpacing.s1)
                                .background(.red.opacity(0.1))
                                .foregroundStyle(.red)
                                .clipShape(Capsule())
                        }
                    }
                    if let username = user.username {
                        HStack(spacing: ConstellationSpacing.s1) {
                            Text("@\(username)")
                            if let email = user.email {
                                Text("·")
                                Text(email)
                            }
                        }
                        .arkType(.cap)
                        .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private var actionsSection: some View {
        Section("Actions") {
            Button {
                showSuspendConfirm = true
            } label: {
                Label(
                    user.status == .suspended ? "Activate User" : "Suspend User",
                    systemImage: user.status == .suspended ? "checkmark.circle" : "nosign"
                )
            }

            if !isSelf {
                Button {
                    showAdminConfirm = true
                } label: {
                    Label(
                        user.isPlatformAdmin == true ? "Revoke Admin" : "Grant Admin",
                        systemImage: user.isPlatformAdmin == true ? "shield.slash" : "shield.checkered"
                    )
                }
            }

            Button {
                showResetMFAConfirm = true
            } label: {
                Label("Reset MFA", systemImage: "key")
            }
        }
    }

    // MARK: - Profile Details

    private var profileSection: some View {
        Section("Profile Details") {
            detailRow("Username", value: user.username.map { "@\($0)" } ?? "Not set")
            detailRow("Email", value: user.email ?? "Not set")
            detailRow("Status", value: (user.status?.rawValue ?? "offline").capitalized)
            if let createdAt = user.createdAt {
                detailRow("Joined", value: createdAt.formatted(date: .abbreviated, time: .omitted))
            }
            if let lastSeen = user.lastSeenAt {
                detailRow("Last Seen", value: lastSeen.formatted(date: .abbreviated, time: .shortened))
            }
        }
    }

    private func detailRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
        }
    }

    // MARK: - Owned Workspaces

    private var ownedWorkspacesSection: some View {
        Section("Owned Workspaces") {
            ForEach(viewModel.userWorkspaces) { workspace in
                NavigationLink {
                    AdminWorkspaceDetailView(viewModel: viewModel, workspace: workspace)
                } label: {
                    HStack {
                        Image(systemName: "crown.fill")
                            .foregroundStyle(.yellow)
                        Text(workspace.name)
                        Spacer()
                        Text("Owner")
                            .arkType(.cap)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Memberships

    private var membershipsSection: some View {
        Section("Workspace Memberships") {
            ForEach(viewModel.userMemberships) { member in
                HStack {
                    Image(systemName: "building.2")
                        .foregroundStyle(.secondary)
                    Text(member.workspaceId.uuidString.prefix(8) + "...")
                    Spacer()
                    Text(member.role.rawValue.capitalized)
                        .arkType(.cap)
                        .padding(.horizontal, ConstellationSpacing.s1)
                        .padding(.vertical, ConstellationSpacing.s1)
                        .background(roleColor(member.role).opacity(0.1))
                        .foregroundStyle(roleColor(member.role))
                        .clipShape(Capsule())
                }
            }
        }
    }

    private func roleColor(_ role: WorkspaceMemberRole) -> Color {
        switch role {
        case .owner: .yellow
        case .admin: .blue
        case .agent: .green
        case .member: .secondary
        }
    }

    // MARK: - Danger Zone

    private var dangerSection: some View {
        Section {
            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                Label("Delete User", systemImage: "trash")
            }
        } header: {
            Text("Danger Zone")
                .foregroundStyle(.red)
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        AdminUserDetailView(
            viewModel: AdminViewModel(),
            user: Profile(id: UUID(), username: "test", displayName: "Test User", email: "test@example.com")
        )
    }
}
#endif
