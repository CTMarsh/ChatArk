import SwiftUI

struct KeyboardShortcutModifier: ViewModifier {
    var onNewConversation: () -> Void = {}
    var onSearch: () -> Void = {}
    var onCloseConversation: () -> Void = {}
    var onNewGroupConversation: () -> Void = {}
    var onOpenSettings: () -> Void = {}

    func body(content: Content) -> some View {
        content
            .background {
                Group {
                    Button("") { onNewConversation() }
                        .keyboardShortcut("n", modifiers: .command)
                    Button("") { onSearch() }
                        .keyboardShortcut("f", modifiers: .command)
                    Button("") { onCloseConversation() }
                        .keyboardShortcut("w", modifiers: .command)
                    Button("") { onNewGroupConversation() }
                        .keyboardShortcut("n", modifiers: [.command, .shift])
                    Button("") { onOpenSettings() }
                        .keyboardShortcut(",", modifiers: .command)
                }
                .frame(width: 0, height: 0)
                .opacity(0)
            }
    }
}

extension View {
    func iPadKeyboardShortcuts(
        onNewConversation: @escaping () -> Void = {},
        onSearch: @escaping () -> Void = {},
        onCloseConversation: @escaping () -> Void = {},
        onNewGroupConversation: @escaping () -> Void = {},
        onOpenSettings: @escaping () -> Void = {}
    ) -> some View {
        modifier(KeyboardShortcutModifier(
            onNewConversation: onNewConversation,
            onSearch: onSearch,
            onCloseConversation: onCloseConversation,
            onNewGroupConversation: onNewGroupConversation,
            onOpenSettings: onOpenSettings
        ))
    }
}
