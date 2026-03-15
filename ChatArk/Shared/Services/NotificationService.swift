import Foundation
import UserNotifications
import Supabase
#if canImport(UIKit)
import UIKit
#endif

@MainActor
final class NotificationService {
    private let client: SupabaseClient
    private var lastRegisteredToken: Data?
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

    private static let notifyBaseURL = "https://notify.noahsark.me"
    private static let notifyAPIKey = "ntfy_dfe1bc2e37d769f64a51b86f2553d44767aafee434bb935b12e4ebc10f8b2226"
    private static let notifyProjectSlug = "chatark"

    func registerDeviceToken(_ token: Data) async throws {
        guard client.auth.currentUser != nil else { return }

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

        #if DEBUG
        let environment = "sandbox"
        #else
        let environment = "production"
        #endif

        // Register with Notify service for push notifications
        var request = URLRequest(url: URL(string: "\(Self.notifyBaseURL)/api/devices/register")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Self.notifyAPIKey, forHTTPHeaderField: "X-API-Key")
        request.httpBody = try JSONEncoder().encode([
            "device_token": tokenString,
            "project_slug": Self.notifyProjectSlug,
            "platform": platform,
            "label": deviceName,
            "environment": environment,
        ])

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            print("[NotificationService] Failed to register device with Notify service")
            return
        }

        lastRegisteredToken = token
    }

    func unregisterDeviceToken() async throws {
        guard let token = lastRegisteredToken else { return }

        let tokenString = token.map { String(format: "%02.2hhx", $0) }.joined()

        var request = URLRequest(url: URL(string: "\(Self.notifyBaseURL)/api/devices/unregister")!)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode([
            "device_token": tokenString,
            "project_slug": Self.notifyProjectSlug,
        ])

        _ = try? await URLSession.shared.data(for: request)
        lastRegisteredToken = nil
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
