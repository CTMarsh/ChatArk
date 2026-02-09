import Foundation
import os.log

private let logger = Logger(subsystem: "com.chrismarsh.chatark", category: "PendingShareHandler")

@MainActor
final class PendingShareHandler {
    static let shared = PendingShareHandler()

    private let suiteName = "group.com.chrismarsh.chatark"
    private let chatService = ChatService()
    private let storageService = StorageService()

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private init() {}

    func processPendingShare(shareId: String) async {
        guard let defaults = UserDefaults(suiteName: suiteName),
              let data = defaults.data(forKey: "pending_share"),
              let share = try? decoder.decode(PendingShare.self, from: data),
              share.id == shareId else {
            logger.error("No pending share found for id: \(shareId, privacy: .public)")
            return
        }

        guard let conversationId = UUID(uuidString: share.conversationId) else {
            logger.error("Invalid conversation ID: \(share.conversationId, privacy: .public)")
            return
        }

        logger.info("Processing pending share \(shareId, privacy: .public) with \(share.items.count) items")

        for item in share.items {
            do {
                switch item.type {
                case .text:
                    if let text = item.text {
                        _ = try await chatService.sendMessage(
                            conversationId: conversationId,
                            content: text,
                            type: .text
                        )
                    }
                case .url:
                    if let urlString = item.text {
                        _ = try await chatService.sendMessage(
                            conversationId: conversationId,
                            content: urlString,
                            type: .text
                        )
                    }
                case .image:
                    if let fileName = item.fileName {
                        try await uploadAndSend(
                            conversationId: conversationId,
                            fileName: fileName,
                            shareId: shareId,
                            messageType: .image,
                            contentType: "image/jpeg"
                        )
                    }
                case .file:
                    if let fileName = item.fileName {
                        try await uploadAndSend(
                            conversationId: conversationId,
                            fileName: fileName,
                            shareId: shareId,
                            messageType: .file,
                            contentType: "application/octet-stream"
                        )
                    }
                }
            } catch {
                logger.error("Failed to process share item: \(error.localizedDescription, privacy: .public)")
            }
        }

        // Clean up
        defaults.removeObject(forKey: "pending_share")
        cleanupShareFiles(shareId: shareId)
        logger.info("Pending share \(shareId, privacy: .public) processed successfully")
    }

    private func uploadAndSend(
        conversationId: UUID,
        fileName: String,
        shareId: String,
        messageType: MessageType,
        contentType: String
    ) async throws {
        let fm = FileManager.default
        guard let shareDir = fm.containerURL(forSecurityApplicationGroupIdentifier: suiteName)?
            .appendingPathComponent("PendingShares", isDirectory: true)
            .appendingPathComponent(shareId, isDirectory: true) else { return }

        let fileUrl = shareDir.appendingPathComponent(fileName)
        guard let fileData = try? Data(contentsOf: fileUrl) else {
            logger.error("Cannot read shared file: \(fileName, privacy: .public)")
            return
        }

        let uploadedUrl = try await storageService.uploadMessageAttachment(
            data: fileData,
            fileName: fileName,
            contentType: contentType,
            conversationId: conversationId
        )

        _ = try await chatService.sendMessage(
            conversationId: conversationId,
            content: fileName,
            type: messageType,
            fileUrl: uploadedUrl,
            fileName: fileName,
            fileSize: Int64(fileData.count),
            fileType: contentType
        )
    }

    private func cleanupShareFiles(shareId: String) {
        let fm = FileManager.default
        guard let shareDir = fm.containerURL(forSecurityApplicationGroupIdentifier: suiteName)?
            .appendingPathComponent("PendingShares", isDirectory: true)
            .appendingPathComponent(shareId, isDirectory: true) else { return }

        try? fm.removeItem(at: shareDir)
    }
}
