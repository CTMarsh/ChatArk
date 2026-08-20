import Foundation

/// Parsed, validated representation of a `chatark://` deep link.
///
/// Extracted out of `ChatArkMain.handleDeepLink` so the parsing rules — which are the
/// only thing standing between an externally-supplied URL and navigation / file paths —
/// can be unit-tested without an app, a window, or a device.
///
/// Both routes require the first path component to be a well-formed UUID. That is the
/// path-traversal guard: a share id is later used to build a directory path inside the
/// App Group container (`PendingShares/<shareId>/`), so a component like `../../` must
/// never reach it.
enum DeepLinkRoute: Equatable, Sendable {
    /// `chatark://conversation/<uuid>`
    case conversation(id: UUID)

    /// `chatark://share/<uuid>`
    ///
    /// Carries the *raw* path component rather than a `UUID`, because
    /// `PendingShareHandler` compares it byte-for-byte against the id the Share
    /// extension wrote (`share.id == shareId`). Round-tripping through
    /// `UUID.uuidString` would upper-case it and break that comparison for any id
    /// that was not already upper-cased. The component is still *validated* as a
    /// UUID — it is simply not rewritten.
    case share(rawId: String)

    static let scheme = "chatark"

    /// Returns the route this URL addresses, or `nil` if it is not a deep link we own
    /// or its identifier is not a valid UUID.
    static func parse(_ url: URL) -> DeepLinkRoute? {
        // RFC 3986: scheme and host are case-insensitive.
        guard url.scheme?.lowercased() == scheme else { return nil }

        // `pathComponents` on `chatark://host/<id>` is ["/", "<id>"].
        guard let identifier = url.pathComponents.dropFirst().first,
              let uuid = UUID(uuidString: identifier) else { return nil }

        switch url.host?.lowercased() {
        case "conversation":
            return .conversation(id: uuid)
        case "share":
            return .share(rawId: identifier)
        default:
            return nil
        }
    }
}
