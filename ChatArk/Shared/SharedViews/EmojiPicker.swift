import SwiftUI

struct EmojiPicker: View {
    let onSelect: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    private let quickEmojis = ["👍", "❤️", "😂", "😮", "😢", "🙏", "🔥", "🎉"]
    private let emojiSections: [(String, [String])] = [
        ("Smileys", ["😀", "😃", "😄", "😁", "😆", "😅", "🤣", "😂", "🙂", "🙃", "😉", "😊", "😇", "🥰", "😍", "🤩", "😘", "😗", "😚", "😙", "🥲", "😋", "😛", "😜", "🤪", "😝", "🤑", "🤗", "🤭", "🤫", "🤔", "🫡", "🤐", "🤨", "😐", "😑", "😶"]),
        ("Gestures", ["👍", "👎", "👊", "✊", "🤛", "🤜", "🤞", "✌️", "🤟", "🤘", "👌", "🤌", "🤏", "👈", "👉", "👆", "👇", "☝️", "✋", "🤚", "🖐", "🖖", "👋", "🤙", "💪", "🙏", "🫶"]),
        ("Hearts", ["❤️", "🧡", "💛", "💚", "💙", "💜", "🖤", "🤍", "🤎", "💔", "❣️", "💕", "💞", "💓", "💗", "💖", "💘", "💝"]),
        ("Objects", ["🔥", "✨", "⭐", "🌟", "💫", "🎉", "🎊", "🏆", "🥇", "🎯", "💡", "🔔", "📌", "✅", "❌", "⚡", "💯", "🚀"]),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Quick reactions
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 8) {
                        ForEach(quickEmojis, id: \.self) { emoji in
                            Button {
                                onSelect(emoji)
                                dismiss()
                            } label: {
                                Text(emoji)
                                    .font(.title)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)

                    Divider()

                    // Full grid
                    ForEach(emojiSections, id: \.0) { section in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(section.0)
                                .font(.headline)
                                .padding(.horizontal)

                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 8) {
                                ForEach(section.1, id: \.self) { emoji in
                                    Button {
                                        onSelect(emoji)
                                        dismiss()
                                    } label: {
                                        Text(emoji)
                                            .font(.title2)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Reactions")
            #if os(iOS) || os(visionOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
