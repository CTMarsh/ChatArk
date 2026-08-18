import SwiftUI

struct PinnedMessageBanner: View {
    let messages: [Message]
    let onTap: (Message) -> Void

    var body: some View {
        if let latest = messages.first {
            Button {
                onTap(latest)
            } label: {
                HStack(spacing: ConstellationSpacing.s1) {
                    Image(systemName: "pin.fill")
                        .arkType(.cap)
                        .foregroundStyle(ConstellationTheme.amber)

                    VStack(alignment: .leading, spacing: ConstellationSpacing.s1) {
                        Text("Pinned Message")
                            .arkType(.cap)
                            .fontWeight(.semibold)
                            .foregroundStyle(ConstellationTheme.amber)

                        Text(latest.content)
                            .arkType(.cap)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    if messages.count > 1 {
                        Text("\(messages.count)")
                            .arkType(.cap)
                            .fontWeight(.bold)
                            .padding(.horizontal, ConstellationSpacing.s1)
                            .padding(.vertical, ConstellationSpacing.s1)
                            .background(ConstellationTheme.amber.opacity(0.2))
                            .clipShape(Capsule())
                    }

                    Image(systemName: "chevron.right")
                        .arkType(.cap)
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal)
                .padding(.vertical, ConstellationSpacing.s1)
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
