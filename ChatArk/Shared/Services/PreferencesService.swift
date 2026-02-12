import Foundation
import Supabase

/// Type-safe preference keys — prevents injection via raw string interpolation in PostgREST filters.
enum PreferenceKey: String, Sendable {
    case theme
    case fontSize = "font_size"
    case accentColor = "accent_color"
    case messageDensity = "message_density"
    case enterKeyBehavior = "enter_key_behavior"
    case linkPreviewsEnabled = "link_previews_enabled"
    case sendTypingIndicators = "send_typing_indicators"
    case sendReadReceipts = "send_read_receipts"
    case emojiSkinTone = "emoji_skin_tone"
    case desktopNotifications = "desktop_notifications"
    case soundNotifications = "sound_notifications"
    case dndEnabled = "dnd_enabled"
    case dndStartTime = "dnd_start_time"
    case dndEndTime = "dnd_end_time"
    case showOnlineStatus = "show_online_status"
    case showReadReceipts = "show_read_receipts"
    case showTypingIndicator = "show_typing_indicator"
    case reduceMotion = "reduce_motion"
    case highContrast = "high_contrast"
    case bio
}

@MainActor
final class PreferencesService {
    private let client: SupabaseClient

    nonisolated init(client: SupabaseClient = supabaseClient) {
        self.client = client
    }

    func fetchPreferences() async throws -> UserPreferences? {
        guard let userId = client.auth.currentUser?.id else {
            throw ChatError.notAuthenticated
        }

        let preferences: [UserPreferences] = try await client.from("user_preferences")
            .select()
            .eq("user_id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value

        return preferences.first
    }

    func updatePreference(key: PreferenceKey, value: AnyJSON) async throws {
        guard let userId = client.auth.currentUser?.id else {
            throw ChatError.notAuthenticated
        }

        try await client.from("user_preferences")
            .update([key.rawValue: value, "updated_at": AnyJSON.string(ISO8601DateFormatter().string(from: Date()))])
            .eq("user_id", value: userId.uuidString)
            .execute()
    }

    func updatePreferences(_ updates: [PreferenceKey: AnyJSON]) async throws {
        guard let userId = client.auth.currentUser?.id else {
            throw ChatError.notAuthenticated
        }

        var allUpdates = Dictionary(uniqueKeysWithValues: updates.map { ($0.key.rawValue, $0.value) })
        allUpdates["updated_at"] = .string(ISO8601DateFormatter().string(from: Date()))

        try await client.from("user_preferences")
            .update(allUpdates)
            .eq("user_id", value: userId.uuidString)
            .execute()
    }

    func createDefaultPreferences() async throws -> UserPreferences {
        guard let userId = client.auth.currentUser?.id else {
            throw ChatError.notAuthenticated
        }

        return try await client.from("user_preferences")
            .insert(["user_id": AnyJSON.string(userId.uuidString)])
            .select()
            .single()
            .execute()
            .value
    }
}
