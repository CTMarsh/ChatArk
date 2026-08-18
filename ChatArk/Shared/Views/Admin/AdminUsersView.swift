import SwiftUI

struct AdminUsersView: View {
    @Bindable var viewModel: AdminViewModel
    @State private var showCreateUser = false

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
                        .arkType(.cap)
                }
            }
        }
        .navigationTitle("Users")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showCreateUser = true
                } label: {
                    Label("Create User", systemImage: "person.badge.plus")
                }
            }
        }
        .sheet(isPresented: $showCreateUser) {
            CreateUserSheet(viewModel: viewModel)
        }
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

            VStack(alignment: .leading, spacing: ConstellationSpacing.s1) {
                HStack(spacing: ConstellationSpacing.s1) {
                    Text(user.displayLabel)
                        .arkType(.body)
                        .fontWeight(.medium)
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

// MARK: - Create User Sheet

struct CreateUserSheet: View {
    @Bindable var viewModel: AdminViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var name = ""
    @State private var sendConfirmation = false
    @State private var isCreating = false
    @State private var createdCredentials: AdminCreateUserResponse?
    @State private var createdEmail = ""
    @State private var copied = false

    var body: some View {
        NavigationStack {
            Form {
                if let creds = createdCredentials {
                    successView(creds)
                } else {
                    formView
                }
            }
            .navigationTitle(createdCredentials != nil ? "User Created" : "Create User")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(createdCredentials != nil ? "Done" : "Cancel") {
                        dismiss()
                    }
                }
                if createdCredentials == nil {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Create") {
                            Task { await createUser() }
                        }
                        .disabled(email.isEmpty || isCreating)
                    }
                }
            }
        }
    }

    private var formView: some View {
        Group {
            Section {
                TextField("Email", text: $email)
                    #if os(iOS) || os(visionOS)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    #endif
                    .autocorrectionDisabled()
                    .textContentType(.emailAddress)

                TextField("Name (optional)", text: $name)
            }

            Section {
                Toggle("Send Confirmation Email", isOn: $sendConfirmation)
            } footer: {
                Text(sendConfirmation
                    ? "User must confirm their email before logging in."
                    : "User can log in immediately — share the generated credentials with them.")
            }

            if let error = viewModel.error {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                        .arkType(.cap)
                }
            }
        }
    }

    private func successView(_ creds: AdminCreateUserResponse) -> some View {
        Group {
            Section("Credentials") {
                VStack(alignment: .leading, spacing: ConstellationSpacing.s1) {
                    Text("Email: \(createdEmail)")
                        .arkType(.body, monospaced: true)
                    Text("Password: \(creds.generatedPassword)")
                        .arkType(.body, monospaced: true)
                }
                .padding(.vertical, ConstellationSpacing.s1)

                Button {
                    #if os(macOS)
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString("Email: \(createdEmail)\nPassword: \(creds.generatedPassword)", forType: .string)
                    #elseif os(iOS) || os(visionOS)
                    UIPasteboard.general.string = "Email: \(createdEmail)\nPassword: \(creds.generatedPassword)"
                    #endif
                    copied = true
                    Task {
                        try? await Task.sleep(for: .seconds(2))
                        copied = false
                    }
                } label: {
                    Label(copied ? "Copied" : "Copy Credentials", systemImage: copied ? "checkmark" : "doc.on.doc")
                }
            }

            Section {
                Label("This password will not be shown again. Share it securely with the user.", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .arkType(.cap)
            }
        }
    }

    private func createUser() async {
        isCreating = true
        defer { isCreating = false }
        createdEmail = email
        createdCredentials = await viewModel.createUser(
            email: email,
            name: name.isEmpty ? nil : name,
            sendConfirmationEmail: sendConfirmation
        )
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        AdminUsersView(viewModel: AdminViewModel())
    }
}
#endif
