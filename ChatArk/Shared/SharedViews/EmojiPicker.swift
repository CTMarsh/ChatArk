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
                VStack(alignment: .leading, spacing: ConstellationSpacing.gapStack) {
                    // Quick reactions
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: ConstellationSpacing.s1) {
                        ForEach(quickEmojis, id: \.self) { emoji in
                            Button {
                                onSelect(emoji)
                                dismiss()
                            } label: {
                                Text(emoji)
                                    .arkType(.stat)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)

                    Divider()

                    // Full grid
                    ForEach(emojiSections, id: \.0) { section in
                        VStack(alignment: .leading, spacing: ConstellationSpacing.s1) {
                            Text(section.0)
                                .arkType(.body)
                                .fontWeight(.semibold)
                                .padding(.horizontal)

                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: ConstellationSpacing.s1) {
                                ForEach(section.1, id: \.self) { emoji in
                                    Button {
                                        onSelect(emoji)
                                        dismiss()
                                    } label: {
                                        Text(emoji)
                                            .arkType(.lead)
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

#if DEBUG
#Preview {
    EmojiPicker(onSelect: { _ in })
}
#endif
