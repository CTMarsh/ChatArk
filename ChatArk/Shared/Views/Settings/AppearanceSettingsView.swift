import SwiftUI
import Supabase

struct AppearanceSettingsView: View {
    @Environment(SettingsViewModel.self) private var viewModel

    var body: some View {
        Form {
            Section("Theme") {
                Picker("Theme", selection: Binding(
                    get: { viewModel.theme },
                    set: { viewModel.updateTheme($0) }
                )) {
                    Text("System").tag(Theme.system)
                    Text("Light").tag(Theme.light)
                    Text("Dark").tag(Theme.dark)
                }
                .pickerStyle(.segmented)
            }

            Section("UI Scale") {
                Picker("UI Scale", selection: Binding(
                    get: { viewModel.uiScale },
                    set: {
                        viewModel.uiScale = $0
                        viewModel.updatePreference(key: .uiScale, value: .string($0.rawValue))
                    }
                )) {
                    Text("Compact").tag(UIScale.compact)
                    Text("Comfortable").tag(UIScale.comfortable)
                    Text("Spacious").tag(UIScale.spacious)
                }
            }

            Section("Font Size") {
                Picker("Font Size", selection: Binding(
                    get: { viewModel.fontSize },
                    set: { viewModel.updateFontSize($0) }
                )) {
                    Text("Small").tag(FontSize.small)
                    Text("Medium").tag(FontSize.medium)
                    Text("Large").tag(FontSize.large)
                }
                .pickerStyle(.segmented)
            }

            Section("Accent Color") {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 12) {
                    ForEach(NauticalTheme.accentPresets, id: \.hex) { preset in
                        VStack(spacing: 4) {
                            Circle()
                                .fill(Color(hex: preset.hex))
                                .frame(width: 36, height: 36)
                                .overlay {
                                    if viewModel.accentColor == preset.hex {
                                        Image(systemName: "checkmark")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundStyle(.white)
                                    }
                                }
                                .onTapGesture {
                                    viewModel.updateAccentColor(preset.hex)
                                }
                            Text(preset.name)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }

            Section("Message Density") {
                Picker("Density", selection: Binding(
                    get: { viewModel.messageDensity },
                    set: {
                        viewModel.messageDensity = $0
                        viewModel.updatePreference(key: .messageDensity, value: .string($0.rawValue))
                    }
                )) {
                    Text("Compact").tag(MessageDensity.compact)
                    Text("Default").tag(MessageDensity.default)
                    Text("Relaxed").tag(MessageDensity.relaxed)
                }
            }
        }
        .navigationTitle("Appearance")
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        AppearanceSettingsView()
    }
    .environment(SettingsViewModel())
}
#endif
