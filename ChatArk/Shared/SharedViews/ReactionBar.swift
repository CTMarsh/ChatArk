import SwiftUI

struct ReactionBar: View {
    let reactions: [ReactionGroup]
    let onTap: (String) -> Void

    var body: some View {
        HStack(spacing: 6) {
            ForEach(reactions) { group in
                Button {
                    onTap(group.emoji)
                } label: {
                    HStack(spacing: 2) {
                        Text(group.emoji)
                            .font(.callout)
                        if group.count > 1 {
                            Text("\(group.count)")
                                .font(.caption2)
                                .foregroundStyle(group.currentUserReacted ? .white : .secondary)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(group.currentUserReacted ? Color.accentColor.opacity(0.3) : Color.gray.opacity(0.12))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
}
