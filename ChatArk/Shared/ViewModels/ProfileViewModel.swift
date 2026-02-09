import Foundation
import SwiftUI
import Supabase

@MainActor
@Observable
final class ProfileViewModel {
    var profile: Profile?
    var isLoading = false
    var error: String?
    var isSaving = false

    // Editable fields
    var displayName = ""
    var username = ""
    var bio = ""

    private let presenceService: PresenceService
    private let preferencesService: PreferencesService
    private let storageService: StorageService

    init(
        presenceService: PresenceService = PresenceService(),
        preferencesService: PreferencesService = PreferencesService(),
        storageService: StorageService = StorageService()
    ) {
        self.presenceService = presenceService
        self.preferencesService = preferencesService
        self.storageService = storageService
    }

    func loadProfile() async {
        guard let userId = SupabaseManager.shared.client.auth.currentUser?.id else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            profile = try await presenceService.fetchProfile(userId: userId)
            if let profile {
                displayName = profile.displayName ?? ""
                username = profile.username ?? ""
            }

            if let prefs = try await preferencesService.fetchPreferences() {
                bio = prefs.bio ?? ""
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func saveProfile() async {
        isSaving = true
        defer { isSaving = false }

        do {
            guard let userId = SupabaseManager.shared.client.auth.currentUser?.id else { return }

            try await SupabaseManager.shared.client.from("profiles")
                .update([
                    "display_name": AnyJSON.string(displayName),
                    "username": AnyJSON.string(username),
                ])
                .eq("id", value: userId.uuidString)
                .execute()

            try await preferencesService.updatePreference(key: "bio", value: .string(bio))
        } catch {
            self.error = error.localizedDescription
        }
    }

    func uploadAvatar(imageData: Data) async -> String? {
        do {
            let url = try await storageService.uploadAvatar(data: imageData, contentType: "image/jpeg")

            guard let userId = SupabaseManager.shared.client.auth.currentUser?.id else { return nil }
            try await SupabaseManager.shared.client.from("profiles")
                .update(["avatar_url": AnyJSON.string(url)])
                .eq("id", value: userId.uuidString)
                .execute()

            profile?.avatarUrl = url
            return url
        } catch {
            self.error = error.localizedDescription
            return nil
        }
    }
}
