import SwiftUI

struct UserSearchView: View {
    @State private var viewModel = SearchViewModel()
    let onSelectUser: (Profile) -> Void

    var body: some View {
        VStack(spacing: 0) {
            SearchBar(text: $viewModel.query, placeholder: "Search users...")
                .padding()
                .onChange(of: viewModel.query) {
                    viewModel.search()
                }

            if viewModel.isSearching {
                ProgressView()
                    .padding()
            } else if viewModel.profileResults.isEmpty && !viewModel.query.isEmpty {
                ContentUnavailableView.search(text: viewModel.query)
            } else {
                List(viewModel.profileResults) { profile in
                    Button {
                        onSelectUser(profile)
                    } label: {
                        HStack(spacing: ConstellationSpacing.gapInline) {
                            ZStack(alignment: .bottomTrailing) {
                                AvatarView(url: profile.avatarUrl, name: profile.displayLabel, size: 44)
                                if let status = profile.status {
                                    StatusIndicator(status: status, size: 12)
                                }
                            }

                            VStack(alignment: .leading, spacing: ConstellationSpacing.s1) {
                                Text(profile.displayLabel)
                                    .arkType(.body)
                                    .fontWeight(.medium)

                                if let username = profile.username {
                                    Text("@\(username)")
                                        .arkType(.cap)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Find People")
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        UserSearchView(onSelectUser: { _ in })
    }
}
#endif
