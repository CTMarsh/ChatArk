#if os(iOS)
import Foundation
import UserNotifications
import SwiftUI
import WatchConnectivity

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        registerNotificationCategories()
        _ = WatchConnectivityManager.shared
        return true
    }

    private func registerNotificationCategories() {
        let replyAction = UNTextInputNotificationAction(
            identifier: "REPLY_ACTION",
            title: "Reply",
            textInputButtonTitle: "Send",
            textInputPlaceholder: "Type a message..."
        )
        let messageCategory = UNNotificationCategory(
            identifier: "MESSAGE",
            actions: [replyAction],
            intentIdentifiers: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([messageCategory])
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Task { @MainActor in
            try? await NotificationService.shared.registerDeviceToken(deviceToken)
        }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }

    // Show notification banner even when app is in foreground.
    // `nonisolated` to match the nonisolated UNUserNotificationCenterDelegate
    // requirement (its non-Sendable UNUserNotificationCenter param cannot cross
    // into the delegate's inferred @MainActor isolation under Swift 6).
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .badge]
    }

    // Handle notification tap or inline reply. `nonisolated` for the same reason;
    // main-actor work (deep-link open) hops via MainActor.run.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        guard let conversationId = userInfo["conversation_id"] as? String,
              let conversationUUID = UUID(uuidString: conversationId) else { return }

        // Handle inline reply
        if let textResponse = response as? UNTextInputNotificationResponse,
           response.actionIdentifier == "REPLY_ACTION" {
            let replyText = textResponse.userText.trimmingCharacters(in: .whitespaces)
            guard !replyText.isEmpty else { return }
            await MainActor.run {
                let chatService = ChatService()
                Task {
                    try? await chatService.sendMessage(
                        conversationId: conversationUUID,
                        content: replyText
                    )
                }
            }
            return
        }

        // Default: open conversation via deep link
        if let url = URL(string: "chatark://conversation/\(conversationId)") {
            await MainActor.run {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }
}
#endif
