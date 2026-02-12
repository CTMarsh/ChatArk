import SwiftUI

struct KeyboardShortcutModifier: ViewModifier {
    var onNewConversation: () -> Void = {}
    var onSearch: () -> Void = {}

    func body(content: Content) -> some View {
        content
            .background {
                Group {
                    Button("") { onNewConversation() }
                        .keyboardShortcut("n", modifiers: .command)
                    Button("") { onSearch() }
                        .keyboardShortcut("f", modifiers: .command)
                }
                .frame(width: 0, height: 0)
                .opacity(0)
            }
    }
}

extension View {
    func iPadKeyboardShortcuts(
        onNewConversation: @escaping () -> Void = {},
        onSearch: @escaping () -> Void = {}
    ) -> some View {
        modifier(KeyboardShortcutModifier(
            onNewConversation: onNewConversation,
            onSearch: onSearch
        ))
    }
}
