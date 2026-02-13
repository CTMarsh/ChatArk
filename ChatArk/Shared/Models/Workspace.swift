import Foundation

struct Workspace: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    var name: String
    var ownerId: UUID
    var createdAt: Date?
    var updatedAt: Date?
    var includeOwnersInAvailability: Bool?

    enum CodingKeys: String, CodingKey {
        case id, name
        case ownerId = "owner_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case includeOwnersInAvailability = "include_owners_in_availability"
    }
}

enum WorkspaceMemberRole: String, Codable, Sendable, CaseIterable {
    case owner
    case admin
    case agent
    case member
}

struct WorkspaceMember: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    var workspaceId: UUID
    var userId: UUID
    var role: WorkspaceMemberRole
    var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case workspaceId = "workspace_id"
        case userId = "user_id"
        case role
        case createdAt = "created_at"
    }
}
