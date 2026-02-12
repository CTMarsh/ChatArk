import Foundation
import Supabase

@MainActor
final class StorageService {
    private let client: SupabaseClient
    static let maxFileSize: Int64 = 50 * 1024 * 1024 // 50MB

    nonisolated init(client: SupabaseClient = supabaseClient) {
        self.client = client
    }

    // MARK: - Upload File

    func uploadMessageAttachment(
        data: Data,
        fileName: String,
        contentType: String,
        conversationId: UUID
    ) async throws -> String {
        guard let userId = client.auth.currentUser?.id else {
            throw ChatError.notAuthenticated
        }

        guard data.count <= Self.maxFileSize else {
            throw StorageError.fileTooLarge
        }

        let validation = FileValidator.validate(data: data, fileName: fileName)
        if !validation.isValid {
            throw StorageError.fileTypeNotAllowed(validation.error ?? "File type not allowed")
        }

        let timestamp = Int(Date().timeIntervalSince1970)
        let ext = (fileName as NSString).pathExtension
        let path = "\(userId.uuidString)/\(conversationId.uuidString)/\(timestamp).\(ext)"

        // Virus scan first
        try await scanFile(data: data, fileName: fileName)

        try await client.storage.from("message-attachments")
            .upload(
                path,
                data: data,
                options: FileOptions(contentType: contentType)
            )

        let publicUrl = try client.storage.from("message-attachments")
            .getPublicURL(path: path)

        return publicUrl.absoluteString
    }

    // MARK: - Upload Avatar

    func uploadAvatar(data: Data, contentType: String) async throws -> String {
        guard let userId = client.auth.currentUser?.id else {
            throw ChatError.notAuthenticated
        }

        guard data.count <= Self.maxFileSize else {
            throw StorageError.fileTooLarge
        }

        let avatarFileName = "avatar.\(contentType == "image/png" ? "png" : "jpg")"
        let validation = FileValidator.validate(data: data, fileName: avatarFileName)
        if !validation.isValid {
            throw StorageError.fileTypeNotAllowed(validation.error ?? "File type not allowed")
        }

        let path = "\(userId.uuidString)/\(avatarFileName)"

        try await client.storage.from("avatars")
            .upload(
                path,
                data: data,
                options: FileOptions(contentType: contentType, upsert: true)
            )

        let publicUrl = try client.storage.from("avatars")
            .getPublicURL(path: path)

        return publicUrl.absoluteString
    }

    // MARK: - Download

    func downloadFile(bucket: String, path: String) async throws -> Data {
        try await client.storage.from(bucket).download(path: path)
    }

    // MARK: - Virus Scan

    private func scanFile(data: Data, fileName: String) async throws {
        // Call the scan-file edge function
        let result: ScanResult = try await client.functions.invoke(
            "scan-file",
            options: FunctionInvokeOptions(
                body: [
                    "fileName": AnyJSON.string(fileName),
                    "fileSize": AnyJSON.integer(data.count),
                ]
            )
        )

        if !result.isClean && !result.skipped {
            throw StorageError.virusDetected(result.message ?? "File failed virus scan")
        }
    }

    // MARK: - Delete

    func deleteFile(bucket: String, paths: [String]) async throws {
        try await client.storage.from(bucket).remove(paths: paths)
    }
}

// MARK: - Scan Result

private struct ScanResult: Codable {
    let isClean: Bool
    let message: String?
    let threats: [String]?
    let skipped: Bool
}

// MARK: - Errors

enum StorageError: LocalizedError {
    case fileTooLarge
    case fileTypeNotAllowed(String)
    case virusDetected(String)
    case uploadFailed
    case downloadFailed

    var errorDescription: String? {
        switch self {
        case .fileTooLarge: "File exceeds the 50MB size limit"
        case .fileTypeNotAllowed(let detail): detail
        case .virusDetected(let message): "File rejected: \(message)"
        case .uploadFailed: "Failed to upload file"
        case .downloadFailed: "Failed to download file"
        }
    }
}
