import SwiftUI

struct AccessibilitySettingsView: View {
    @Environment(SettingsViewModel.self) private var viewModel

    var body: some View {
        Form {
            Section {
                Toggle("Reduce Motion", isOn: Binding(
                    get: { viewModel.reduceMotion },
                    set: { viewModel.toggleReduceMotion($0) }
                ))

                Toggle("High Contrast", isOn: Binding(
                    get: { viewModel.highContrast },
                    set: { viewModel.toggleHighContrast($0) }
                ))
            } footer: {
                Text("These settings apply to the chat interface. System accessibility settings are respected automatically.")
            }
        }
        .navigationTitle("Accessibility")
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        AccessibilitySettingsView()
    }
    .environment(SettingsViewModel())
}
#endif
