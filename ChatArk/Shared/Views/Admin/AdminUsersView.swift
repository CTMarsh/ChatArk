import SwiftUI

struct AdminUsersView: View {
    @Bindable var viewModel: AdminViewModel

    var body: some View {
        List {
            Section {
                TextField("Search by username, name, or email...", text: $viewModel.userSearch)
                    #if os(iOS) || os(visionOS)
                    .textInputAutocapitalization(.never)
                    #endif
                    .autocorrectionDisabled()
                    .onSubmit {
                        Task { await viewModel.loadUsers() }
                    }
            }

            Section {
                if viewModel.isLoading {
                    ProgressView()
                } else if viewModel.users.isEmpty {
                    Text("No users found")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.users) { user in
                        NavigationLink {
                            AdminUserDetailView(viewModel: viewModel, user: user)
                        } label: {
                            userRow(user)
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
        .navigationTitle("Users")
        .task {
            await viewModel.loadUsers()
        }
    }

    private func userRow(_ user: Profile) -> some View {
        HStack {
            AvatarView(
                url: user.avatarUrl,
                name: user.displayLabel,
                size: 36
            )
            .overlay(alignment: .bottomTrailing) {
                Circle()
                    .fill(statusColor(user.status))
                    .frame(width: 10, height: 10)
                    .overlay(
                        Circle().stroke(.background, lineWidth: 1.5)
                    )
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(user.displayLabel)
                        .font(.body)
                        .fontWeight(.medium)
                    if user.isPlatformAdmin == true {
                        Text("Admin")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.red.opacity(0.2))
                            .foregroundStyle(.red)
                            .clipShape(Capsule())
                    }
                    if user.status == .suspended {
                        Text("Suspended")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.red.opacity(0.1))
                            .foregroundStyle(.red)
                            .clipShape(Capsule())
                    }
                }
                if let username = user.username {
                    HStack(spacing: 4) {
                        Text("@\(username)")
                        if let email = user.email {
                            Text("·")
                            Text(email)
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                }
            }
        }
    }

    private func statusColor(_ status: UserStatus?) -> Color {
        switch status {
        case .online: .green
        case .away: .yellow
        case .dnd: .red
        case .suspended: .red.opacity(0.6)
        case .offline, .none: .gray
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        AdminUsersView(viewModel: AdminViewModel())
    }
}
#endif
