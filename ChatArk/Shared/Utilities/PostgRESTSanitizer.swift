import Foundation

enum PostgRESTSanitizer {
    /// Escapes special PostgREST filter characters to prevent filter injection.
    /// Characters: . % * ( ) ,
    /// Note: `&` is NOT escaped here because the Supabase Swift SDK uses URLComponents/URLQueryItem
    /// which percent-encodes `&` to `%26` at the transport layer automatically.
    static func sanitize(_ input: String) -> String {
        var result = input
        for char in ["\\", ".", "%", "*", "(", ")", ","] {
            result = result.replacingOccurrences(of: char, with: "\\\(char)")
        }
        return result
    }
}
