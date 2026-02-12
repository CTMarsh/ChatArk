import SwiftUI
import UserNotifications
import Supabase
#if canImport(UIKit)
import UIKit
#endif

struct NotificationSettingsView: View {
    @Environment(SettingsViewModel.self) private var viewModel
    @State private var notificationPermission: UNAuthorizationStatus = .notDetermined
    @State private var dndStartDate = Calendar.current.date(from: DateComponents(hour: 22)) ?? Date()
    @State private var dndEndDate = Calendar.current.date(from: DateComponents(hour: 7)) ?? Date()

    var body: some View {
        Form {
            Section {
                if notificationPermission != .authorized {
                    Button("Enable Notifications") {
                        Task {
                            let granted = try? await NotificationService.shared.requestPermission()
                            notificationPermission = await NotificationService.shared.checkPermission()
                            if granted == true {
                                #if os(iOS)
                                UIApplication.shared.registerForRemoteNotifications()
                                #elseif os(macOS)
                                NSApplication.shared.registerForRemoteNotifications()
                                #endif
                            }
                        }
                    }
                }

                Toggle("Push Notifications", isOn: Binding(
                    get: { viewModel.desktopNotifications },
                    set: {
                        viewModel.desktopNotifications = $0
                        viewModel.updatePreference(key: .desktopNotifications, value: .bool($0))
                    }
                ))

                Toggle("Sound", isOn: Binding(
                    get: { viewModel.soundNotifications },
                    set: {
                        viewModel.soundNotifications = $0
                        viewModel.updatePreference(key: .soundNotifications, value: .bool($0))
                    }
                ))
            }

            Section("Do Not Disturb") {
                Toggle("Do Not Disturb", isOn: Binding(
                    get: { viewModel.dndEnabled },
                    set: { viewModel.toggleDND($0) }
                ))

                if viewModel.dndEnabled {
                    DatePicker("From", selection: $dndStartDate, displayedComponents: .hourAndMinute)
                        .onChange(of: dndStartDate) {
                            let formatter = DateFormatter()
                            formatter.dateFormat = "HH:mm"
                            let timeString = formatter.string(from: dndStartDate)
                            viewModel.dndStartTime = timeString
                            viewModel.updatePreference(key: .dndStartTime, value: .string(timeString))
                        }

                    DatePicker("To", selection: $dndEndDate, displayedComponents: .hourAndMinute)
                        .onChange(of: dndEndDate) {
                            let formatter = DateFormatter()
                            formatter.dateFormat = "HH:mm"
                            let timeString = formatter.string(from: dndEndDate)
                            viewModel.dndEndTime = timeString
                            viewModel.updatePreference(key: .dndEndTime, value: .string(timeString))
                        }
                }
            }
        }
        .navigationTitle("Notifications")
        .task {
            notificationPermission = await NotificationService.shared.checkPermission()
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            if !viewModel.dndStartTime.isEmpty, let date = formatter.date(from: viewModel.dndStartTime) {
                dndStartDate = date
            }
            if !viewModel.dndEndTime.isEmpty, let date = formatter.date(from: viewModel.dndEndTime) {
                dndEndDate = date
            }
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        NotificationSettingsView()
    }
    .environment(SettingsViewModel())
}
#endif
