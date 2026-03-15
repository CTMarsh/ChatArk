import UserNotifications
import WidgetKit
import os.log

private let logger = Logger(subsystem: "com.chrismarsh.chatark.notificationservice", category: "NotificationService")

class NotificationServiceExtension: UNNotificationServiceExtension {
    private var contentHandler: ((UNNotificationContent) -> Void)?
    private var bestAttemptContent: UNMutableNotificationContent?

    private static let appGroupId = "group.com.chrismarsh.chatark"

    private static let allowedDownloadHosts = [
        "supabase.noahsark.me",
    ]

    private static func isAllowedURL(_ url: URL) -> Bool {
        guard let host = url.host?.lowercased() else { return false }
        return allowedDownloadHosts.contains(where: { host.hasSuffix($0) })
            && url.path.contains("/storage/")
    }

    private static var cacheDirectory: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupId)?
            .appendingPathComponent("AvatarCache", isDirectory: true)
    }

    private static let maxCacheSizeBytes: Int64 = 50 * 1024 * 1024 // 50MB
    private static let maxCacheAgeSeconds: TimeInterval = 7 * 24 * 3600 // 7 days

    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        evictStaleCache()

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

        // Set category for actionable notifications (matches MESSAGE category in AppDelegate)
        content.categoryIdentifier = "MESSAGE"

        Task {
            var attachments: [UNNotificationAttachment] = []

            // Avatar attachment (only from allowed Supabase storage domains)
            if let avatarUrlString = userInfo["avatar_url"] as? String,
               let avatarUrl = URL(string: avatarUrlString),
               Self.isAllowedURL(avatarUrl) {
                if let attachment = await downloadWithCache(url: avatarUrl, identifier: "avatar") {
                    attachments.append(attachment)
                }
            }

            // Image message attachment (only from allowed Supabase storage domains)
            if let messageType = userInfo["message_type"] as? String,
               messageType == "image",
               let fileUrlString = userInfo["file_url"] as? String,
               let fileUrl = URL(string: fileUrlString),
               Self.isAllowedURL(fileUrl) {
                logger.info("Downloading image attachment")
                if let attachment = await downloadAttachment(url: fileUrl, identifier: "image") {
                    attachments.append(attachment)
                }
            }

            content.attachments = attachments

            // Refresh widget timelines so widgets show latest data
            WidgetCenter.shared.reloadAllTimelines()

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

    // MARK: - Cache Eviction

    private func evictStaleCache() {
        guard let cacheDir = Self.cacheDirectory else { return }
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(at: cacheDir, includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey]) else { return }

        let now = Date()
        var totalSize: Int64 = 0
        var fileInfos: [(url: URL, date: Date, size: Int64)] = []

        for file in files {
            guard let attrs = try? file.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey]),
                  let date = attrs.contentModificationDate,
                  let size = attrs.fileSize else { continue }
            let fileSize = Int64(size)

            // Delete files older than max age
            if now.timeIntervalSince(date) > Self.maxCacheAgeSeconds {
                try? fm.removeItem(at: file)
                continue
            }

            totalSize += fileSize
            fileInfos.append((file, date, fileSize))
        }

        // If over size limit, delete oldest first
        if totalSize > Self.maxCacheSizeBytes {
            let sorted = fileInfos.sorted { $0.date < $1.date }
            for info in sorted {
                guard totalSize > Self.maxCacheSizeBytes else { break }
                try? fm.removeItem(at: info.url)
                totalSize -= info.size
            }
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
