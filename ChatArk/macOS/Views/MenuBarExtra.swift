import SwiftUI

#if os(macOS)
struct MenuBarExtraContent: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var unreadCount = 0

    var body: some View {
        VStack(spacing: 8) {
            if authViewModel.isAuthenticated {
                HStack {
                    Circle()
                        .fill(.green)
                        .frame(width: 8, height: 8)
                    Text("Online")
                        .font(.caption)
                    Spacer()
                    if unreadCount > 0 {
                        Text("\(unreadCount) unread")
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                }

                Divider()

                Button("Open ChatArk") {
                    NSApplication.shared.activate(ignoringOtherApps: true)
                }

                Button("New Conversation") {
                    NSApplication.shared.activate(ignoringOtherApps: true)
                }
                .keyboardShortcut("n", modifiers: .command)

                Divider()

                Menu("Status") {
                    Button("Online") { }
                    Button("Away") { }
                    Button("Do Not Disturb") { }
                    Button("Invisible") { }
                }

                Divider()

                Button("Quit ChatArk") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q", modifiers: .command)
            } else {
                Text("Not signed in")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button("Open ChatArk") {
                    NSApplication.shared.activate(ignoringOtherApps: true)
                }
            }
        }
        .padding(8)
        .frame(width: 220)
    }
}
#endif
