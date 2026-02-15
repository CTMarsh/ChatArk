import Foundation
import Supabase

struct AdminAuditLog: Codable, Identifiable, Sendable {
    let id: UUID
    var adminId: UUID
    var action: String
    var targetType: String
    var targetId: String?
    var metadata: [String: AnyJSON]?
    var createdAt: Date?
    var adminProfile: AuditAdminProfile?

    enum CodingKeys: String, CodingKey {
        case id
        case adminId = "admin_id"
        case action
        case targetType = "target_type"
        case targetId = "target_id"
        case metadata
        case createdAt = "created_at"
        case adminProfile = "profiles"
    }

    var actionLabel: String {
        switch action {
        case "user_created": "User Created"
        case "user_suspended": "User Suspended"
        case "user_activated": "User Activated"
        case "user_deleted": "User Deleted"
        case "user_mfa_reset": "MFA Reset"
        case "admin_granted": "Admin Granted"
        case "admin_revoked": "Admin Revoked"
        case "workspace_created": "Workspace Created"
        case "workspace_updated": "Workspace Updated"
        case "workspace_suspended": "Workspace Suspended"
        case "workspace_activated": "Workspace Activated"
        case "workspace_deleted": "Workspace Deleted"
        case "workspace_member_added": "Member Added"
        case "workspace_member_removed": "Member Removed"
        case "workspace_member_role_changed": "Role Changed"
        case "widget_created": "Widget Created"
        case "widget_updated": "Widget Updated"
        case "widget_deleted": "Widget Deleted"
        case "setting_updated": "Setting Updated"
        default: action.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    var isDestructive: Bool {
        ["user_suspended", "user_deleted", "workspace_suspended", "workspace_deleted",
         "workspace_member_removed", "widget_deleted"].contains(action)
    }

    var adminDisplayName: String {
        adminProfile?.displayName ?? adminProfile?.username ?? "Unknown"
    }
}

struct AuditAdminProfile: Codable, Sendable {
    var displayName: String?
    var username: String?

    enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
        case username
    }
}
