import UserNotifications
import WidgetKit
import os.log

private let logger = Logger(subsystem: "com.chrismarsh.chatark.notificationservice", category: "NotificationService")

/// Serializes one-shot delivery of a notification between the async download
/// `Task` (started in `didReceive`) and `serviceExtensionTimeWillExpire()`.
///
/// The system runs the extension on a background serial queue, but it can invoke
/// `serviceExtensionTimeWillExpire()` while the download `Task` (on the
/// cooperative pool) is still in flight — so the two delivery paths genuinely
/// race for `contentHandler` and `bestAttemptContent`. `UNMutableNotificationContent`,
/// `UNNotificationAttachment`, and the content-handler closure are all non-`Sendable`
/// (the UserNotifications framework is not yet concurrency-audited), so this box
/// holds them behind an `NSLock` and guarantees the handler fires exactly once.
///
/// `@unchecked Sendable` is sound here because the box exposes no mutable state
/// except through `lock`-guarded methods; nothing escapes the lock.
private final class DeliveryBox: @unchecked Sendable {
    private let lock = NSLock()
    private var contentHandler: ((UNNotificationContent) -> Void)?
    private var bestAttemptContent: UNMutableNotificationContent?

    func arm(content: UNMutableNotificationContent, handler: @escaping (UNNotificationContent) -> Void) {
        lock.lock()
        defer { lock.unlock() }
        bestAttemptContent = content
        contentHandler = handler
    }

    /// Delivers the best-attempt content exactly once, optionally applying freshly
    /// downloaded attachments first. Whichever caller wins (download completion or
    /// timeout) disarms the box; every later call is a no-op.
    @discardableResult
    func deliver(applying attachments: [UNNotificationAttachment]? = nil) -> Bool {
        lock.lock()
        guard let handler = contentHandler, let content = bestAttemptContent else {
            lock.unlock()
            return false
        }
        if let attachments { content.attachments = attachments }
        contentHandler = nil
        bestAttemptContent = nil
        lock.unlock()

        handler(content)
        return true
    }
}

final class NotificationServiceExtension: UNNotificationServiceExtension {
    private let delivery = DeliveryBox()

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
        Self.evictStaleCache()

        guard let content = request.content.mutableCopy() as? UNMutableNotificationContent else {
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

        // Extract the Sendable inputs the download task needs, so the task closure
        // captures only Sendable values (the box + these strings) — never `self`
        // or the non-Sendable content/handler.
        let avatarUrlString = userInfo["avatar_url"] as? String
        let messageType = userInfo["message_type"] as? String
        let fileUrlString = userInfo["file_url"] as? String

        // Hand ownership of the content + handler to the delivery box before the
        // async work begins; both delivery paths now go through it.
        delivery.arm(content: content, handler: contentHandler)

        // The task captures only Sendable values (the box + the extracted strings) —
        // never `self` or the non-Sendable content/handler. All download logic lives
        // in a nonisolated static function so the task closure stays trivial and the
        // region-based isolation checker has nothing cross-isolation to reason about.
        let box = delivery
        Task {
            await Self.buildAndDeliver(
                avatarURLString: avatarUrlString,
                messageType: messageType,
                fileURLString: fileUrlString,
                delivery: box
            )
        }
    }

    /// Downloads any avatar/image attachments and hands the finished set to the
    /// delivery box. Nonisolated with all-`Sendable` inputs, so nothing crosses an
    /// isolation boundary; the non-`Sendable` attachments never leave this call.
    private static func buildAndDeliver(
        avatarURLString: String?,
        messageType: String?,
        fileURLString: String?,
        delivery: DeliveryBox
    ) async {
        var attachments: [UNNotificationAttachment] = []

        // Avatar attachment (only from allowed Supabase storage domains)
        if let avatarURLString,
           let avatarURL = URL(string: avatarURLString),
           isAllowedURL(avatarURL) {
            if let attachment = await downloadWithCache(url: avatarURL, identifier: "avatar") {
                attachments.append(attachment)
            }
        }

        // Image message attachment (only from allowed Supabase storage domains)
        if messageType == "image",
           let fileURLString,
           let fileURL = URL(string: fileURLString),
           isAllowedURL(fileURL) {
            logger.info("Downloading image attachment")
            if let attachment = await downloadAttachment(url: fileURL, identifier: "image") {
                attachments.append(attachment)
            }
        }

        // Refresh widget timelines so widgets show latest data
        WidgetCenter.shared.reloadAllTimelines()

        delivery.deliver(applying: attachments)
    }

    override func serviceExtensionTimeWillExpire() {
        logger.warning("Service extension time expiring, delivering best attempt")
        delivery.deliver()
    }

    // MARK: - Download with Cache

    private static func downloadWithCache(url: URL, identifier: String) async -> UNNotificationAttachment? {
        let fm = FileManager.default
        let cacheKey = url.absoluteString.data(using: .utf8)?.base64EncodedString() ?? UUID().uuidString

        // Ensure cache directory exists
        guard let cacheDir = cacheDirectory else {
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

    private static func evictStaleCache() {
        guard let cacheDir = cacheDirectory else { return }
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
            if now.timeIntervalSince(date) > maxCacheAgeSeconds {
                try? fm.removeItem(at: file)
                continue
            }

            totalSize += fileSize
            fileInfos.append((file, date, fileSize))
        }

        // If over size limit, delete oldest first
        if totalSize > maxCacheSizeBytes {
            let sorted = fileInfos.sorted { $0.date < $1.date }
            for info in sorted {
                guard totalSize > maxCacheSizeBytes else { break }
                try? fm.removeItem(at: info.url)
                totalSize -= info.size
            }
        }
    }

    // MARK: - Direct Download (no cache)

    private static func downloadAttachment(url: URL, identifier: String) async -> UNNotificationAttachment? {
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
