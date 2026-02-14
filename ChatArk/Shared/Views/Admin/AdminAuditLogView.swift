import SwiftUI

struct AdminAuditLogView: View {
    @Bindable var viewModel: AdminViewModel

    private let actionFilters = [
        ("", "All Actions"),
        ("user_suspended", "User Suspended"),
        ("user_activated", "User Activated"),
        ("user_deleted", "User Deleted"),
        ("user_mfa_reset", "MFA Reset"),
        ("admin_granted", "Admin Granted"),
        ("admin_revoked", "Admin Revoked"),
        ("workspace_created", "Workspace Created"),
        ("workspace_updated", "Workspace Updated"),
        ("workspace_suspended", "Workspace Suspended"),
        ("workspace_activated", "Workspace Activated"),
        ("workspace_deleted", "Workspace Deleted"),
        ("workspace_member_added", "Member Added"),
        ("workspace_member_removed", "Member Removed"),
        ("workspace_member_role_changed", "Role Changed"),
        ("widget_created", "Widget Created"),
        ("widget_updated", "Widget Updated"),
        ("widget_deleted", "Widget Deleted"),
        ("setting_updated", "Setting Updated"),
    ]

    var body: some View {
        List {
            Section {
                Picker("Filter", selection: $viewModel.auditFilter) {
                    ForEach(actionFilters, id: \.0) { filter in
                        Text(filter.1).tag(filter.0)
                    }
                }
                .onChange(of: viewModel.auditFilter) {
                    Task { await viewModel.loadAuditLogs() }
                }
            }

            Section {
                if viewModel.isLoading {
                    ProgressView()
                } else if viewModel.auditLogs.isEmpty {
                    Text("No audit log entries")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.auditLogs) { log in
                        logRow(log)
                    }
                }
            }

            if let error = viewModel.error {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }
        }
        .navigationTitle("Audit Log")
        .task {
            await viewModel.loadAuditLogs()
        }
    }

    private func logRow(_ log: AdminAuditLog) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(log.actionLabel)
                    .font(.callout)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(log.isDestructive ? .red.opacity(0.15) : .blue.opacity(0.1))
                    .foregroundStyle(log.isDestructive ? .red : .primary)
                    .clipShape(Capsule())

                Text("on \(log.targetType)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                if let targetId = log.targetId {
                    Text(String(targetId.prefix(8)) + "...")
                        .font(.caption.monospaced())
                        .foregroundStyle(.tertiary)
                }

                if let createdAt = log.createdAt {
                    Text(createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        AdminAuditLogView(viewModel: AdminViewModel())
    }
}
#endif
