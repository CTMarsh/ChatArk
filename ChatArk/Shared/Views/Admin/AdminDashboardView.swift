import SwiftUI

struct AdminDashboardView: View {
    @State private var viewModel = AdminViewModel()

    var body: some View {
        List {
            overviewSection
            navigationSection
        }
        .navigationTitle("Platform Admin")
        .task {
            await viewModel.loadDashboard()
        }
    }

    // MARK: - Overview

    private var overviewSection: some View {
        Section("Overview") {
            if viewModel.isLoading {
                ProgressView()
            } else if let metrics = viewModel.metrics {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                ], spacing: ConstellationSpacing.gapInline) {
                    statCard("Total Users", value: metrics.totalUsers, icon: "person.2")
                    statCard("Active Today", value: metrics.activeToday, icon: "waveform.path.ecg")
                    statCard("Workspaces", value: metrics.totalWorkspaces, icon: "building.2")
                    statCard("Widgets", value: metrics.totalWidgets, icon: "widget.small")
                    statCard("Conversations", value: metrics.totalConversations, icon: "bubble.left.and.bubble.right")
                    statCard("Today", value: metrics.conversationsToday, icon: "bubble.left")
                    statCard("Messages", value: metrics.totalMessages, icon: "envelope")
                    statCard("Today", value: metrics.messagesToday, icon: "paperplane")
                }
                .padding(.vertical, ConstellationSpacing.s1)
            }

            if let error = viewModel.error {
                Text(error)
                    .foregroundStyle(.red)
                    .arkType(.cap)
            }
        }
    }

    private func statCard(_ title: String, value: Int, icon: String) -> some View {
        VStack(alignment: .leading, spacing: ConstellationSpacing.s1) {
            HStack {
                Image(systemName: icon)
                    .arkType(.cap)
                    .foregroundStyle(.red.opacity(0.8))
                Spacer()
            }
            Text("\(value)")
                .arkType(.lead)
                .fontWeight(.bold)
            Text(title)
                .arkType(.cap)
                .foregroundStyle(.secondary)
        }
        .padding(ConstellationSpacing.gapInline)
        .background(.red.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Navigation

    private var navigationSection: some View {
        Section("Administration") {
            NavigationLink {
                AdminUsersView(viewModel: viewModel)
            } label: {
                Label("Users", systemImage: "person.2")
                    .foregroundStyle(.red)
            }

            NavigationLink {
                AdminWorkspacesView(viewModel: viewModel)
            } label: {
                Label("Workspaces", systemImage: "building.2")
                    .foregroundStyle(.red)
            }

            NavigationLink {
                AdminAuditLogView(viewModel: viewModel)
            } label: {
                Label("Audit Log", systemImage: "scroll")
                    .foregroundStyle(.red)
            }

            NavigationLink {
                AdminPlatformSettingsView(viewModel: viewModel)
            } label: {
                Label("Platform Settings", systemImage: "gearshape")
                    .foregroundStyle(.red)
            }
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        AdminDashboardView()
    }
}
#endif
