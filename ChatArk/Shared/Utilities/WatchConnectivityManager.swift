#if os(iOS) || os(watchOS)
import Foundation
import WatchConnectivity
import CryptoKit
import os.log

private let logger = Logger(subsystem: "com.chrismarsh.chatark", category: "WatchConnectivity")

final class WatchConnectivityManager: NSObject, WCSessionDelegate, Sendable {
    static let shared = WatchConnectivityManager()

    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    // MARK: - iOS: Send data to watch

    #if os(iOS)
    func sendUnreadCount(_ count: Int, recentNames: [String]) {
        guard WCSession.default.activationState == .activated else {
            logger.info("WCSession not activated, skipping transfer")
            return
        }

        guard WCSession.default.isComplicationEnabled else {
            logger.info("Complication not enabled on watch")
            let userInfo: [String: Any] = [
                "unread_count": count,
                "recent_names": recentNames,
                "timestamp": Date().timeIntervalSince1970
            ]
            WCSession.default.transferUserInfo(userInfo)
            return
        }

        let userInfo: [String: Any] = [
            "unread_count": count,
            "recent_names": recentNames,
            "timestamp": Date().timeIntervalSince1970
        ]

        WCSession.default.transferCurrentComplicationUserInfo(userInfo)
        logger.info("Transferred complication data: \(count) unread")
    }

    func sendAuthSession(accessToken: String, refreshToken: String) {
        guard WCSession.default.activationState == .activated else {
            logger.info("WCSession not activated, skipping auth transfer")
            return
        }

        // Encrypt tokens before sending over Bluetooth
        guard let encAccess = AppGroupEncryption.encryptString(accessToken),
              let encRefresh = AppGroupEncryption.encryptString(refreshToken) else {
            logger.error("Failed to encrypt auth tokens for watch transfer")
            return
        }

        do {
            try WCSession.default.updateApplicationContext([
                "auth_access_token_enc": encAccess,
                "auth_refresh_token_enc": encRefresh
            ])
            logger.info("Sent encrypted auth session to watch via applicationContext")
        } catch {
            logger.error("Failed to send auth session: \(error.localizedDescription, privacy: .public)")
        }
    }
    #endif

    // MARK: - watchOS: Read received auth data

    #if os(watchOS)
    func receivedAuthSession() -> (accessToken: String, refreshToken: String)? {
        let context = WCSession.default.receivedApplicationContext

        guard let encAccess = context["auth_access_token_enc"] as? Data,
              let encRefresh = context["auth_refresh_token_enc"] as? Data,
              let accessToken = AppGroupEncryption.decryptString(encAccess),
              let refreshToken = AppGroupEncryption.decryptString(encRefresh) else {
            return nil
        }
        return (accessToken, refreshToken)
    }
    #endif

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error {
            logger.error("WCSession activation failed: \(error.localizedDescription, privacy: .public)")
            // Retry activation after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                if WCSession.isSupported() && WCSession.default.activationState != .activated {
                    logger.info("Retrying WCSession activation")
                    WCSession.default.activate()
                }
            }
        } else {
            logger.info("WCSession activated: \(String(describing: activationState.rawValue))")
        }

        #if os(watchOS)
        if activationState == .activated {
            NotificationCenter.default.post(name: .watchSessionDidReceiveAuth, object: nil)
        }
        #endif
    }

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        logger.info("WCSession became inactive")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        logger.info("WCSession deactivated, reactivating")
        session.activate()
    }

    func session(_ session: WCSession, didFinish userInfoTransfer: WCSessionUserInfoTransfer, error: Error?) {
        if let error {
            logger.error("UserInfo transfer failed: \(error.localizedDescription, privacy: .public)")
            // Retry the transfer
            let userInfo = userInfoTransfer.userInfo
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                if session.activationState == .activated {
                    session.transferUserInfo(userInfo)
                    logger.info("Retried userInfo transfer")
                }
            }
        }
    }
    #endif

    #if os(watchOS)
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        logger.info("Received application context from iPhone")
        if applicationContext["auth_access_token_enc"] != nil {
            NotificationCenter.default.post(name: .watchSessionDidReceiveAuth, object: nil)
        }
    }
    #endif
}

#if os(watchOS)
extension Notification.Name {
    static let watchSessionDidReceiveAuth = Notification.Name("watchSessionDidReceiveAuth")
}
#endif
#endif // os(iOS) || os(watchOS)
