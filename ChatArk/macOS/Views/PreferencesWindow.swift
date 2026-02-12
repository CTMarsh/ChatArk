import SwiftUI
import Supabase

#if os(macOS)
struct PreferencesWindow: View {
    @State private var selectedTab = "general"

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("General", systemImage: "gearshape", value: "general") {
                GeneralPreferences()
            }

            Tab("Appearance", systemImage: "paintbrush", value: "appearance") {
                AppearanceSettingsView()
            }

            Tab("Notifications", systemImage: "bell", value: "notifications") {
                NotificationSettingsView()
            }

            Tab("Privacy", systemImage: "hand.raised", value: "privacy") {
                PrivacySettingsView()
            }

            Tab("Security", systemImage: "lock.shield", value: "security") {
                SecuritySettingsView()
            }
        }
        .frame(width: 500, height: 400)
    }
}

struct GeneralPreferences: View {
    @Environment(SettingsViewModel.self) private var viewModel

    var body: some View {
        Form {
            Section("Messages") {
                Picker("Enter Key", selection: Binding(
                    get: { viewModel.enterKeyBehavior },
                    set: {
                        viewModel.enterKeyBehavior = $0
                        viewModel.updatePreference(key: .enterKeyBehavior, value: .string($0.rawValue))
                    }
                )) {
                    Text("Send Message").tag(EnterKeyBehavior.send)
                    Text("New Line").tag(EnterKeyBehavior.newline)
                }

                Toggle("Link Previews", isOn: Binding(
                    get: { viewModel.linkPreviewsEnabled },
                    set: {
                        viewModel.linkPreviewsEnabled = $0
                        viewModel.updatePreference(key: .linkPreviewsEnabled, value: .bool($0))
                    }
                ))

                Toggle("Send Typing Indicators", isOn: Binding(
                    get: { viewModel.sendTypingIndicators },
                    set: {
                        viewModel.sendTypingIndicators = $0
                        viewModel.updatePreference(key: .sendTypingIndicators, value: .bool($0))
                    }
                ))

                Toggle("Send Read Receipts", isOn: Binding(
                    get: { viewModel.sendReadReceipts },
                    set: {
                        viewModel.sendReadReceipts = $0
                        viewModel.updatePreference(key: .sendReadReceipts, value: .bool($0))
                    }
                ))
            }

            Section("Accessibility") {
                Toggle("Reduce Motion", isOn: Binding(
                    get: { viewModel.reduceMotion },
                    set: { viewModel.toggleReduceMotion($0) }
                ))

                Toggle("High Contrast", isOn: Binding(
                    get: { viewModel.highContrast },
                    set: { viewModel.toggleHighContrast($0) }
                ))
            }
        }
        .padding()
    }
}

#if DEBUG
#Preview {
    PreferencesWindow()
        .environment(SettingsViewModel())
}
#endif
#endif
