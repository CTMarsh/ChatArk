import SwiftUI

struct PinnedMessageBanner: View {
    let messages: [Message]
    let onTap: (Message) -> Void

    var body: some View {
        if let latest = messages.first {
            Button {
                onTap(latest)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "pin.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Pinned Message")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.orange)

                        Text(latest.content)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    if messages.count > 1 {
                        Text("\(messages.count)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2))
                            .clipShape(Capsule())
                    }

                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
            }
            .buttonStyle(.plain)
        }
    }
}
