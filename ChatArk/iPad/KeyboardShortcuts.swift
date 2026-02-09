import SwiftUI

struct KeyboardShortcutModifier: ViewModifier {
    @State private var showSearch = false
    @State private var showNewConversation = false

    func body(content: Content) -> some View {
        content
            .keyboardShortcut("n", modifiers: .command) // New conversation
            .keyboardShortcut("f", modifiers: .command) // Search
            .keyboardShortcut("e", modifiers: [.command, .shift]) // Emoji
    }
}

extension View {
    func iPadKeyboardShortcuts() -> some View {
        modifier(KeyboardShortcutModifier())
    }
}
