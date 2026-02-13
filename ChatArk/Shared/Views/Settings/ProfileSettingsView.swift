import SwiftUI
import PhotosUI

struct ProfileSettingsView: View {
    @State private var viewModel = ProfileViewModel()
    @State private var selectedPhoto: PhotosPickerItem?

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
