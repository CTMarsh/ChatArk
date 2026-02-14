import SwiftUI
import PhotosUI

struct ProfileSettingsView: View {
    @State private var viewModel = ProfileViewModel()
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedStatus: UserStatus = .online
    private let presenceService = PresenceService()

    var body: some View {
        Form {
            Section {
                HStack {
                    Spacer()
                    VStack {
                        AvatarView(
                            url: viewModel.profile?.avatarUrl,
                            name: viewModel.displayName.isEmpty ? "?" : viewModel.displayName,
                            size: 80
                        )

                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            Text("Change Photo")
                                .font(.caption)
                        }
                        .onChange(of: selectedPhoto) { _, newValue in
                            guard let item = newValue else { return }
                            Task {
                                if let data = try? await item.loadTransferable(type: Data.self) {
                                    _ = await viewModel.uploadAvatar(imageData: data)
                                }
                            }
                        }
                    }
                    Spacer()
                }
            }

            Section("Display Name") {
                TextField("Display Name", text: $viewModel.displayName)
                    .onChange(of: viewModel.displayName) {
                        if viewModel.displayName.count > 100 {
                            viewModel.displayName = String(viewModel.displayName.prefix(100))
                        }
                    }
            }

            Section("Username") {
                TextField("Username", text: $viewModel.username)
                    #if os(iOS) || os(visionOS)
                    .textInputAutocapitalization(.never)
                    #endif
                    .autocorrectionDisabled()
                    .onChange(of: viewModel.username) {
                        if viewModel.username.count > 50 {
                            viewModel.username = String(viewModel.username.prefix(50))
                        }
                    }
            }

            Section("Bio") {
                TextField("Tell others about yourself", text: $viewModel.bio, axis: .vertical)
                    .lineLimit(3...6)
            }

            Section("Status") {
                Picker("Online Status", selection: $selectedStatus) {
                    Label("Online", systemImage: "circle.fill")
                        .foregroundStyle(.green)
                        .tag(UserStatus.online)
                    Label("Away", systemImage: "clock.fill")
                        .foregroundStyle(.yellow)
                        .tag(UserStatus.away)
                    Label("Do Not Disturb", systemImage: "minus.circle.fill")
                        .foregroundStyle(.red)
                        .tag(UserStatus.dnd)
                    Label("Invisible", systemImage: "eye.slash.fill")
                        .foregroundStyle(.secondary)
                        .tag(UserStatus.offline)
                }
                .onChange(of: selectedStatus) {
                    Task { try? await presenceService.updateStatus(selectedStatus) }
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
        .navigationTitle("Profile")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task { await viewModel.saveProfile() }
                }
                .disabled(viewModel.isSaving)
            }
        }
        .task {
            await viewModel.loadProfile()
            if let status = viewModel.profile?.status {
                selectedStatus = status
            }
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        ProfileSettingsView()
    }
}
#endif
