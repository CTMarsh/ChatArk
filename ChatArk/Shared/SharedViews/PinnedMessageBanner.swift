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
                        .foregroundStyle(ConstellationTheme.amber)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Pinned Message")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(ConstellationTheme.amber)

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
                            .background(ConstellationTheme.amber.opacity(0.2))
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

#if DEBUG
#Preview {
    PinnedMessageBanner(messages: [PreviewData.pinnedMessage], onTap: { _ in })
}
#endif
