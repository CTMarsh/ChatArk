#if os(macOS)
import Foundation
import UserNotifications
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().delegate = self
        registerNotificationCategories()
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
        _ application: NSApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Task { @MainActor in
            try? await NotificationService.shared.registerDeviceToken(deviceToken)
        }
    }

    func application(
        _ application: NSApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .badge]
    }

    func userNotificationCenter(
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
            NSWorkspace.shared.open(url)
        }
    }
}
#endif
