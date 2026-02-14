import Foundation

struct PlatformSetting: Codable, Identifiable, Hashable, Sendable {
    var key: String
    var value: String
    var description: String?
    var updatedAt: Date?
    var updatedBy: UUID?

    var id: String { key }

    enum CodingKeys: String, CodingKey {
        case key, value, description
        case updatedAt = "updated_at"
        case updatedBy = "updated_by"
    }

    var displayName: String {
        switch key {
        case "max_workspace_members": "Max Workspace Members"
        case "max_workspaces_per_user": "Max Workspaces Per User"
        case "max_file_size_mb": "Max File Size (MB)"
        case "max_widgets_per_workspace": "Max Widgets Per Workspace"
        case "allow_signups": "Allow Signups"
        default: key.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    var isToggle: Bool {
        value == "true" || value == "false"
    }
}
