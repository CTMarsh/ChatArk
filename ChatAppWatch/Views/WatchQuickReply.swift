#if os(watchOS)
import SwiftUI

struct WatchQuickReply: View {
    let conversationId: UUID
    let onSend: (String) -> Void
    @State private var messageText = ""
    @Environment(\.dismiss) private var dismiss

    private let quickReplies = [
        "OK", "Thanks!", "On my way",
        "Be right back", "Sure", "No problem",
        "See you later", "Got it"
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                Text("Quick Reply")
                    .font(.headline)

                // Predefined replies
                ForEach(quickReplies, id: \.self) { reply in
                    Button {
                        onSend(reply)
                    } label: {
                        Text(reply)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }

                Divider()

                // Custom text via dictation
                TextField("Dictate...", text: $messageText)
                    .font(.caption)

                if !messageText.isEmpty {
                    Button("Send") {
                        onSend(messageText)
                    }
                    .buttonStyle(.borderedProminent)
                }

                Button("Cancel") {
                    dismiss()
                }
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
        }
    }
}
#endif
