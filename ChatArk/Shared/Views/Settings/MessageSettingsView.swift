import SwiftUI
import Supabase

struct MessageSettingsView: View {
    @Environment(SettingsViewModel.self) private var viewModel

    var body: some View {
        Form {
            Section("Compose") {
                Picker("Enter Key", selection: Binding(
                    get: { viewModel.enterKeyBehavior },
                    set: {
                        viewModel.enterKeyBehavior = $0
                        viewModel.updatePreference(key: "enter_key_behavior", value: .string($0.rawValue))
                    }
                )) {
                    Text("Send Message").tag(EnterKeyBehavior.send)
                    Text("New Line").tag(EnterKeyBehavior.newline)
                }

                Toggle("Link Previews", isOn: Binding(
                    get: { viewModel.linkPreviewsEnabled },
                    set: {
                        viewModel.linkPreviewsEnabled = $0
                        viewModel.updatePreference(key: "link_previews_enabled", value: .bool($0))
                    }
                ))
            }

            Section("Indicators") {
                Toggle("Send Typing Indicators", isOn: Binding(
                    get: { viewModel.sendTypingIndicators },
                    set: {
                        viewModel.sendTypingIndicators = $0
                        viewModel.updatePreference(key: "send_typing_indicators", value: .bool($0))
                    }
                ))

                Toggle("Send Read Receipts", isOn: Binding(
                    get: { viewModel.sendReadReceipts },
                    set: {
                        viewModel.sendReadReceipts = $0
                        viewModel.updatePreference(key: "send_read_receipts", value: .bool($0))
                    }
                ))
            }

            Section("Emoji") {
                Picker("Default Skin Tone", selection: Binding(
                    get: { viewModel.emojiSkinTone },
                    set: {
                        viewModel.emojiSkinTone = $0
                        viewModel.updatePreference(key: "emoji_skin_tone", value: .string($0.rawValue))
                    }
                )) {
                    Text("👋").tag(EmojiSkinTone.default)
                    Text("👋🏻").tag(EmojiSkinTone.light)
                    Text("👋🏼").tag(EmojiSkinTone.mediumLight)
                    Text("👋🏽").tag(EmojiSkinTone.medium)
                    Text("👋🏾").tag(EmojiSkinTone.mediumDark)
                    Text("👋🏿").tag(EmojiSkinTone.dark)
                }
            }
        }
        .navigationTitle("Messages")
    }
}
