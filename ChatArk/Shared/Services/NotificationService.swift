import Foundation
import UserNotifications
import Supabase
#if canImport(UIKit)
import UIKit
#endif

@MainActor
final class NotificationService {
    private let client: SupabaseClient
    static let shared = NotificationService()

    private init() {
        self.client = supabaseClient
    }

    // MARK: - Permission

    func requestPermission() async throws -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
        return granted
    }

    func checkPermission() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }

    // MARK: - Device Token Registration

    func registerDeviceToken(_ token: Data) async throws {
        guard let userId = client.auth.currentUser?.id else { return }

        let tokenString = token.map { String(format: "%02.2hhx", $0) }.joined()

        #if os(iOS)
        let platform = "ios"
        let deviceName = UIDevice.current.name
        #elseif os(macOS)
        let platform = "macos"
        let deviceName = Host.current().localizedName ?? "Mac"
        #elseif os(watchOS)
        let platform = "watchos"
        let deviceName = "Apple Watch"
        #else
        let platform = "unknown"
        let deviceName = "Unknown"
        #endif

        try await client.from("push_tokens")
            .upsert(
                [
                    "user_id": AnyJSON.string(userId.uuidString),
                    "token": AnyJSON.string(tokenString),
                    "platform": AnyJSON.string(platform),
                    "device_name": AnyJSON.string(deviceName),
                    "updated_at": AnyJSON.string(ISO8601DateFormatter().string(from: Date())),
                ],
                onConflict: "token"
            )
            .execute()
    }

    func unregisterDeviceToken() async throws {
        guard let userId = client.auth.currentUser?.id else { return }

        try await client.from("push_tokens")
            .delete()
            .eq("user_id", value: userId.uuidString)
            .execute()
    }

    // MARK: - In-App Notifications

    func fetchNotifications(limit: Int = 50) async throws -> [AppNotification] {
        guard let userId = client.auth.currentUser?.id else {
            throw ChatError.notAuthenticated
        }

        return try await client.from("notifications")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
    }

    func markNotificationRead(id: UUID) async throws {
        try await client.from("notifications")
            .update(["is_read": AnyJSON.bool(true)])
            .eq("id", value: id.uuidString)
            .execute()
    }

    func markAllRead() async throws {
        guard let userId = client.auth.currentUser?.id else { return }

        try await client.from("notifications")
            .update(["is_read": AnyJSON.bool(true)])
            .eq("user_id", value: userId.uuidString)
            .eq("is_read", value: false)
            .execute()
    }

    func getUnreadCount() async throws -> Int {
        guard let userId = client.auth.currentUser?.id else { return 0 }

        let notifications: [AppNotification] = try await client.from("notifications")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("is_read", value: false)
            .execute()
            .value

        return notifications.count
    }

    // MARK: - Local Notification

    func scheduleLocalNotification(title: String, body: String, conversationId: UUID? = nil) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        if let conversationId {
            content.userInfo = ["conversation_id": conversationId.uuidString]
            content.threadIdentifier = conversationId.uuidString
        }

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Badge

    func updateBadgeCount(_ count: Int) {
        #if os(iOS)
        UNUserNotificationCenter.current().setBadgeCount(count)
        #endif
    }
}
