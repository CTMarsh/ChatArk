import SwiftUI
import Supabase

struct AdminAuditLogView: View {
    @Bindable var viewModel: AdminViewModel

    private let actionFilters = [
        ("", "All Actions"),
        ("user_created", "User Created"),
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
                        .arkType(.cap)
                }
            }
        }
        .navigationTitle("Audit Log")
        .task {
            await viewModel.loadAuditLogs()
        }
    }

    private func logRow(_ log: AdminAuditLog) -> some View {
        VStack(alignment: .leading, spacing: ConstellationSpacing.s1) {
            HStack(spacing: ConstellationSpacing.s1) {
                Text(log.actionLabel)
                    .arkType(.body)
                    .fontWeight(.medium)
                    .padding(.horizontal, ConstellationSpacing.s1)
                    .padding(.vertical, ConstellationSpacing.s1)
                    .background(log.isDestructive ? .red.opacity(0.15) : .blue.opacity(0.1))
                    .foregroundStyle(log.isDestructive ? .red : .primary)
                    .clipShape(Capsule())

                Text("on \(log.targetType)")
                    .arkType(.cap)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: ConstellationSpacing.s1) {
                // Admin who performed the action
                Text(log.adminDisplayName)
                    .arkType(.cap)
                    .fontWeight(.medium)

                if let targetId = log.targetId {
                    Text("·")
                        .arkType(.cap)
                        .foregroundStyle(.tertiary)
                    Text(String(targetId.prefix(8)) + "...")
                        .arkType(.cap, monospaced: true)
                        .foregroundStyle(.tertiary)
                }

                if let createdAt = log.createdAt {
                    Text("·")
                        .arkType(.cap)
                        .foregroundStyle(.tertiary)
                    Text(createdAt.formatted(date: .abbreviated, time: .shortened))
                        .arkType(.cap)
                        .foregroundStyle(.secondary)
                }
            }

            // Metadata display
            if let metadata = log.metadata, !metadata.isEmpty {
                Text(metadataString(metadata))
                    .arkType(.cap, monospaced: true)
                    .foregroundStyle(.tertiary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, ConstellationSpacing.s1)
    }

    private func metadataString(_ metadata: [String: AnyJSON]) -> String {
        let parts = metadata.compactMap { key, value -> String? in
            switch value {
            case .string(let s): return "\(key): \(s)"
            case .bool(let b): return "\(key): \(b)"
            case .double(let d): return "\(key): \(Int(d))"
            default: return nil
            }
        }
        return parts.joined(separator: ", ")
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        AdminAuditLogView(viewModel: AdminViewModel())
    }
}
#endif
