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
                HStack {
                    ForEach(["#3b82f6", "#ef4444", "#22c55e", "#a855f7", "#f97316", "#ec4899"], id: \.self) { color in
                        Circle()
                            .fill(Color(hex: color))
                            .frame(width: 36, height: 36)
                            .overlay {
                                if viewModel.accentColor == color {
                                    Image(systemName: "checkmark")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.white)
                                }
                            }
                            .onTapGesture {
                                viewModel.updateAccentColor(color)
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
                        viewModel.updatePreference(key: "message_density", value: .string($0.rawValue))
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

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let scanner = Scanner(string: hex)
        var color: UInt64 = 0
        scanner.scanHexInt64(&color)

        let r = Double((color >> 16) & 0xFF) / 255.0
        let g = Double((color >> 8) & 0xFF) / 255.0
        let b = Double(color & 0xFF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}
