import SwiftUI

struct AdminPlatformSettingsView: View {
    @Bindable var viewModel: AdminViewModel

    var body: some View {
        List {
            limitsSection
            featuresSection
        }
        .navigationTitle("Platform Settings")
        .task {
            await viewModel.loadPlatformSettings()
        }
    }

    // MARK: - Limits

    private var limitsSection: some View {
        Section {
            ForEach(limitSettings) { setting in
                settingRow(setting)
            }
        } header: {
            Text("Limits")
        } footer: {
            Text("Platform resource limits")
        }
    }

    // MARK: - Features

    private var featuresSection: some View {
        Section {
            ForEach(featureSettings) { setting in
                toggleRow(setting)
            }
        } header: {
            Text("Features")
        } footer: {
            Text("Platform feature toggles")
        }
    }

    private func settingRow(_ setting: PlatformSetting) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(setting.displayName)
                    .arkType(.body)
                if let desc = setting.description {
                    Text(desc)
                        .arkType(.cap)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            TextField("", text: Binding(
                get: { setting.value },
                set: { newValue in
                    Task { await viewModel.updateSetting(key: setting.key, value: newValue) }
                }
            ))
            .frame(width: 60)
            #if os(iOS) || os(visionOS)
            .keyboardType(.numberPad)
            #endif
            .multilineTextAlignment(.trailing)
        }
    }

    private func toggleRow(_ setting: PlatformSetting) -> some View {
        Toggle(isOn: Binding(
            get: { setting.value == "true" },
            set: { newValue in
                Task { await viewModel.updateSetting(key: setting.key, value: newValue ? "true" : "false") }
            }
        )) {
            VStack(alignment: .leading) {
                Text(setting.displayName)
                    .arkType(.body)
                if let desc = setting.description {
                    Text(desc)
                        .arkType(.cap)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Computed

    private var limitSettings: [PlatformSetting] {
        viewModel.platformSettings.filter { !$0.isToggle }
    }

    private var featureSettings: [PlatformSetting] {
        viewModel.platformSettings.filter { $0.isToggle }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        AdminPlatformSettingsView(viewModel: AdminViewModel())
    }
}
#endif
