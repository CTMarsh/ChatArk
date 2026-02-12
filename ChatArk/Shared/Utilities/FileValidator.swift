import Foundation
import UniformTypeIdentifiers

enum FileValidator {
    static let maxFileSize: Int64 = 50 * 1024 * 1024 // 50MB

    static let allowedImageTypes: Set<UTType> = [.jpeg, .png, .gif, .webP, .heic]

    static let allowedFileTypes: Set<UTType> = [
        .pdf, .plainText, .rtf,
        .zip, .gzip,
        .mpeg4Movie,
        .mp3, .wav,
        .spreadsheet, .presentation,
    ]

    /// All types allowed for upload (images + documents)
    static var allAllowedTypes: Set<UTType> {
        allowedImageTypes.union(allowedFileTypes)
    }

    struct ValidationResult: Sendable {
        let isValid: Bool
        let error: String?
    }

    static func validate(data: Data, fileName: String) -> ValidationResult {
        if Int64(data.count) > maxFileSize {
            return ValidationResult(
                isValid: false,
                error: "File exceeds 50MB limit (\(formatFileSize(Int64(data.count))))"
            )
        }

        let ext = (fileName as NSString).pathExtension.lowercased()
        if !ext.isEmpty {
            guard let fileType = UTType(filenameExtension: ext),
                  allAllowedTypes.contains(where: { fileType.conforms(to: $0) }) else {
                return ValidationResult(
                    isValid: false,
                    error: "File type .\(ext) is not allowed"
                )
            }
        }

        return ValidationResult(isValid: true, error: nil)
    }

    static func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    static func isImage(contentType: String) -> Bool {
        guard let type = UTType(mimeType: contentType) else { return false }
        return type.conforms(to: .image)
    }

    static func mimeType(for fileName: String) -> String {
        let ext = (fileName as NSString).pathExtension
        if let type = UTType(filenameExtension: ext) {
            return type.preferredMIMEType ?? "application/octet-stream"
        }
        return "application/octet-stream"
    }
}
