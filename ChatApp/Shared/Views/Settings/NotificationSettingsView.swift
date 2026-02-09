import SwiftUI
import UserNotifications
import Supabase

struct NotificationSettingsView: View {
    @Environment(SettingsViewModel.self) private var viewModel
    @State private var notificationPermission: UNAuthorizationStatus = .notDetermined

    var body: some View {
        Form {
            Section {
                if notificationPermission != .authorized {
                    Button("Enable Notifications") {
                        Task {
                            _ = try? await NotificationService.shared.requestPermission()
                            notificationPermission = await NotificationService.shared.checkPermission()
                        }
                    }
                }

                Toggle("Push Notifications", isOn: Binding(
                    get: { viewModel.desktopNotifications },
                    set: {
                        viewModel.desktopNotifications = $0
                        viewModel.updatePreference(key: "desktop_notifications", value: .bool($0))
                    }
                ))

                Toggle("Sound", isOn: Binding(
                    get: { viewModel.soundNotifications },
                    set: {
                        viewModel.soundNotifications = $0
                        viewModel.updatePreference(key: "sound_notifications", value: .bool($0))
                    }
                ))
            }

            Section("Do Not Disturb") {
                Toggle("Do Not Disturb", isOn: Binding(
                    get: { viewModel.dndEnabled },
                    set: { viewModel.toggleDND($0) }
                ))

                if viewModel.dndEnabled {
                    HStack {
                        Text("From")
                        Spacer()
                        Text(viewModel.dndStartTime.isEmpty ? "22:00" : viewModel.dndStartTime)
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("To")
                        Spacer()
                        Text(viewModel.dndEndTime.isEmpty ? "07:00" : viewModel.dndEndTime)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Notifications")
        .task {
            notificationPermission = await NotificationService.shared.checkPermission()
        }
    }
}
