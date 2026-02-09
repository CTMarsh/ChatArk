import SwiftUI

struct MentionSuggestionView: View {
    let participants: [Profile]
    let query: String
    let onSelect: (Profile) -> Void

    var filteredParticipants: [Profile] {
        if query.isEmpty {
            return participants
        }
        let lowerQuery = query.lowercased()
        return participants.filter {
            ($0.username?.lowercased().contains(lowerQuery) ?? false) ||
            ($0.displayName?.lowercased().contains(lowerQuery) ?? false)
        }
    }

    var body: some View {
        if !filteredParticipants.isEmpty {
            VStack(spacing: 0) {
                ForEach(filteredParticipants) { profile in
                    Button {
                        onSelect(profile)
                    } label: {
                        HStack(spacing: 10) {
                            AvatarView(url: profile.avatarUrl, name: profile.displayLabel, size: 28)

                            VStack(alignment: .leading, spacing: 1) {
                                Text(profile.displayLabel)
                                    .font(.subheadline)
                                    .fontWeight(.medium)

                                if let username = profile.username {
                                    Text("@\(username)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)

                    Divider()
                }
            }
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(radius: 4)
            .frame(maxHeight: 200)
        }
    }
}
