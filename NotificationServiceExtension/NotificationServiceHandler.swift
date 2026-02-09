import UserNotifications
import os.log

private let logger = Logger(subsystem: "com.chrismarsh.chatark.notificationservice", category: "NotificationService")

class NotificationServiceExtension: UNNotificationServiceExtension {
    private var contentHandler: ((UNNotificationContent) -> Void)?
    private var bestAttemptContent: UNMutableNotificationContent?

    private static let appGroupId = "group.com.chrismarsh.chatark"

    private static var cacheDirectory: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupId)?
            .appendingPathComponent("AvatarCache", isDirectory: true)
    }

    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

        guard let content = bestAttemptContent else {
            contentHandler(request.content)
            return
        }

        let userInfo = content.userInfo
        logger.info("Processing notification: \(content.title, privacy: .public)")

        // Thread identifier for conversation grouping
        if let conversationId = userInfo["conversation_id"] as? String {
            content.threadIdentifier = conversationId
        }

        // Set category for actionable notifications
        content.categoryIdentifier = "CHAT_MESSAGE"

        Task {
            var attachments: [UNNotificationAttachment] = []

            // Avatar attachment
            if let avatarUrlString = userInfo["avatar_url"] as? String,
               let avatarUrl = URL(string: avatarUrlString) {
                if let attachment = await downloadWithCache(url: avatarUrl, identifier: "avatar") {
                    attachments.append(attachment)
                }
            }

            // Image message attachment
            if let messageType = userInfo["message_type"] as? String,
               messageType == "image",
               let fileUrlString = userInfo["file_url"] as? String,
               let fileUrl = URL(string: fileUrlString) {
                logger.info("Downloading image attachment")
                if let attachment = await downloadAttachment(url: fileUrl, identifier: "image") {
                    attachments.append(attachment)
                }
            }

            content.attachments = attachments
            contentHandler(content)
        }
    }

    override func serviceExtensionTimeWillExpire() {
        logger.warning("Service extension time expiring, delivering best attempt")
        if let contentHandler, let content = bestAttemptContent {
            contentHandler(content)
        }
    }

    // MARK: - Download with Cache

    private func downloadWithCache(url: URL, identifier: String) async -> UNNotificationAttachment? {
        let fm = FileManager.default
        let cacheKey = url.absoluteString.data(using: .utf8)?.base64EncodedString() ?? UUID().uuidString

        // Ensure cache directory exists
        guard let cacheDir = Self.cacheDirectory else {
            logger.error("Cannot access app group container for cache")
            return await downloadAttachment(url: url, identifier: identifier)
        }

        if !fm.fileExists(atPath: cacheDir.path) {
            try? fm.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        }

        let cachedFile = cacheDir.appendingPathComponent(cacheKey + ".jpg")

        // Cache hit
        if fm.fileExists(atPath: cachedFile.path) {
            logger.info("Cache hit for \(identifier, privacy: .public)")
            let tmpFile = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".jpg")
            do {
                try fm.copyItem(at: cachedFile, to: tmpFile)
                return try UNNotificationAttachment(
                    identifier: identifier,
                    url: tmpFile,
                    options: [UNNotificationAttachmentOptionsThumbnailHiddenKey: false]
                )
            } catch {
                logger.error("Cache hit copy failed: \(error.localizedDescription, privacy: .public)")
            }
        }

        // Cache miss — download
        logger.info("Cache miss for \(identifier, privacy: .public), downloading")
        guard let (data, response) = try? await URLSession.shared.data(from: url) else {
            logger.error("Download failed for \(url.absoluteString, privacy: .public)")
            return nil
        }

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200,
              !data.isEmpty else {
            logger.error("Invalid response for \(identifier, privacy: .public)")
            return nil
        }

        // Write to cache
        try? data.write(to: cachedFile)

        // Write to tmp for attachment
        let tmpFile = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".jpg")
        do {
            try data.write(to: tmpFile)
            return try UNNotificationAttachment(
                identifier: identifier,
                url: tmpFile,
                options: [UNNotificationAttachmentOptionsThumbnailHiddenKey: false]
            )
        } catch {
            logger.error("Attachment creation failed: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    // MARK: - Direct Download (no cache)

    private func downloadAttachment(url: URL, identifier: String) async -> UNNotificationAttachment? {
        guard let (data, response) = try? await URLSession.shared.data(from: url) else {
            logger.error("Download failed for \(url.absoluteString, privacy: .public)")
            return nil
        }

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200,
              !data.isEmpty else {
            return nil
        }

        let ext = url.pathExtension.isEmpty ? "jpg" : url.pathExtension
        let tmpFile = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".\(ext)")
        do {
            try data.write(to: tmpFile)
            return try UNNotificationAttachment(
                identifier: identifier,
                url: tmpFile,
                options: nil
            )
        } catch {
            logger.error("Attachment creation failed: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }
}
