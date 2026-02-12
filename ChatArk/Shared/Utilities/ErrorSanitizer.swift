import Foundation

enum ErrorSanitizer {
    /// Returns a user-safe error message, stripping database/API schema details
    /// that could expose table names, column names, or constraint information.
    static func sanitize(_ error: Error) -> String {
        // Our own error enums already have user-friendly messages
        if error is ChatError || error is ConversationError || error is StorageError {
            return error.localizedDescription
        }

        let desc = error.localizedDescription
        let lower = desc.lowercased()

        // Detect PostgREST/PostgreSQL error patterns that expose schema info
        let schemaPatterns = [
            "relation \"", "column \"", "violates", "constraint \"",
            "schema \"", "pg_", "operator does not exist", "permission denied for",
            "does not exist", "already exists", "not-null",
            "unique_violation", "foreign_key_violation", "pgrst",
        ]

        if schemaPatterns.contains(where: { lower.contains($0) }) {
            return "Something went wrong. Please try again."
        }

        return desc
    }
}
