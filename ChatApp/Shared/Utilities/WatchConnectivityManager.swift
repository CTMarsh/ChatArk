#if os(iOS)
import Foundation
import WatchConnectivity
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

    func sendUnreadCount(_ count: Int, recentNames: [String]) {
        guard WCSession.default.activationState == .activated else {
            logger.info("WCSession not activated, skipping transfer")
            return
        }

        guard WCSession.default.isComplicationEnabled else {
            logger.info("Complication not enabled on watch")
            // Fall back to regular transfer
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

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error {
            logger.error("WCSession activation failed: \(error.localizedDescription, privacy: .public)")
        } else {
            logger.info("WCSession activated: \(String(describing: activationState.rawValue))")
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        logger.info("WCSession became inactive")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        logger.info("WCSession deactivated, reactivating")
        session.activate()
    }
}
#endif
