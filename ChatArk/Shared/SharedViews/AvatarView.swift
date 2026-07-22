import SwiftUI
import NukeUI

struct AvatarView: View {
    let url: String?
    let name: String
    var size: CGFloat = 40

    var body: some View {
        Group {
            if let url, let imageUrl = URL(string: url), imageUrl.scheme == "https" {
                LazyImage(url: imageUrl) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        fallbackAvatar
                    }
                }
                .frame(width: size, height: size)
                .clipShape(Circle())
            } else {
                fallbackAvatar
            }
        }
        .accessibilityLabel("\(name) avatar")
        .accessibilityHidden(true)
    }

    private var fallbackAvatar: some View {
        Circle()
            .fill(avatarColor)
            .frame(width: size, height: size)
            .overlay {
                Text(initials)
                    .font(.system(size: size * 0.4, weight: .semibold))
                    .foregroundStyle(.white)
            }
    }

    private var initials: String {
        let components = name.split(separator: " ")
        let first = components.first?.prefix(1) ?? ""
        let second = components.count > 1 ? components[1].prefix(1) : ""
        return "\(first)\(second)".uppercased()
    }

    private var avatarColor: Color {
        let hash = abs(name.hashValue)
        return ConstellationTheme.avatarColors[hash % ConstellationTheme.avatarColors.count]
    }
}

#if DEBUG
#Preview("Initials") {
    HStack(spacing: 12) {
        AvatarView(url: nil, name: "Alice Johnson", size: 48)
        AvatarView(url: nil, name: "Bob Smith", size: 48)
        AvatarView(url: nil, name: "Carol Williams", size: 48)
    }
    .padding()
}
#endif
