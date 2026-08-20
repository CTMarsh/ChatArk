import XCTest

/// `DeepLinkRoute.parse` is the only validation between an arbitrary externally-opened
/// URL and (a) in-app navigation and (b) a directory path built inside the App Group
/// container (`PendingShares/<shareId>/`). Everything it lets through is trusted
/// downstream, so the interesting cases here are the rejections.
final class DeepLinkRouteTests: XCTestCase {

    private let uuidUpper = "3F2504E0-4F89-11D3-9A0C-0305E82C3301"
    private let uuidLower = "3f2504e0-4f89-11d3-9a0c-0305e82c3301"

    // MARK: - Accepted

    func testParsesConversationLink() {
        let route = parse("chatark://conversation/\(uuidUpper)")
        XCTAssertEqual(route, .conversation(id: UUID(uuidString: uuidUpper)!))
    }

    func testParsesConversationLinkWithLowercaseUUID() {
        let route = parse("chatark://conversation/\(uuidLower)")
        XCTAssertEqual(route, .conversation(id: UUID(uuidString: uuidLower)!))
    }

    func testParsesShareLink() {
        XCTAssertEqual(parse("chatark://share/\(uuidUpper)"), .share(rawId: uuidUpper))
    }

    /// `PendingShareHandler` compares the id byte-for-byte against what the Share
    /// extension stored (`share.id == shareId`). Parsing must therefore hand back the
    /// component exactly as it arrived — normalising it through `UUID.uuidString` would
    /// upper-case it and silently break every lower-cased share.
    func testShareLinkPreservesRawCasing() {
        XCTAssertEqual(parse("chatark://share/\(uuidLower)"), .share(rawId: uuidLower))
    }

    /// Scheme and host are case-insensitive per RFC 3986. A link that arrives
    /// upper-cased (some senders normalise) must still resolve.
    func testSchemeAndHostAreCaseInsensitive() {
        XCTAssertEqual(parse("CHATARK://CONVERSATION/\(uuidUpper)"),
                       .conversation(id: UUID(uuidString: uuidUpper)!))
    }

    /// Current behaviour: only the first path component is read, trailing segments are
    /// ignored. Pinned deliberately — it is lenient, but the id is still UUID-validated,
    /// so the extra segments reach nothing.
    func testExtraPathSegmentsAreIgnored() {
        XCTAssertEqual(parse("chatark://conversation/\(uuidUpper)/messages/42"),
                       .conversation(id: UUID(uuidString: uuidUpper)!))
    }

    // MARK: - Rejected: wrong scheme or host

    func testRejectsForeignScheme() {
        XCTAssertNil(parse("https://conversation/\(uuidUpper)"))
        XCTAssertNil(parse("chatarkx://conversation/\(uuidUpper)"))
        XCTAssertNil(parse("file://conversation/\(uuidUpper)"))
    }

    func testRejectsUnknownHost() {
        XCTAssertNil(parse("chatark://admin/\(uuidUpper)"))
        XCTAssertNil(parse("chatark://settings/\(uuidUpper)"))
    }

    // MARK: - Rejected: malformed identifier

    func testRejectsMissingIdentifier() {
        XCTAssertNil(parse("chatark://conversation"))
        XCTAssertNil(parse("chatark://share"))
    }

    func testRejectsEmptyIdentifier() {
        XCTAssertNil(parse("chatark://conversation/"))
        XCTAssertNil(parse("chatark://share/"))
    }

    func testRejectsNonUUIDIdentifier() {
        XCTAssertNil(parse("chatark://conversation/not-a-uuid"))
        XCTAssertNil(parse("chatark://share/12345"))
        // Right shape, wrong length — one hex digit short of a UUID.
        XCTAssertNil(parse("chatark://share/3F2504E0-4F89-11D3-9A0C-0305E82C330"))
    }

    // MARK: - Rejected: path traversal

    /// The share id becomes a directory name inside the App Group container. A traversal
    /// payload must not survive parsing — in any of the forms a sender might encode it.
    func testRejectsPathTraversalInShareId() {
        for payload in [
            "chatark://share/../../../etc/passwd",
            "chatark://share/..%2F..%2Fetc%2Fpasswd",
            "chatark://share/%2e%2e%2f%2e%2e%2fpasswd",
            "chatark://share/....//....//passwd"
        ] {
            // Nil is the safe outcome whether Foundation refuses to build the URL at all
            // or builds one whose first component is not a UUID.
            XCTAssertNil(URL(string: payload).flatMap(DeepLinkRoute.parse),
                         "traversal payload was not rejected: \(payload)")
        }
    }

    func testRejectsAbsolutePathInShareId() {
        XCTAssertNil(URL(string: "chatark://share/%2Fetc%2Fpasswd").flatMap(DeepLinkRoute.parse))
    }

    // MARK: - Helper

    private func parse(_ string: String) -> DeepLinkRoute? {
        guard let url = URL(string: string) else {
            XCTFail("test fixture is not a URL: \(string)")
            return nil
        }
        return DeepLinkRoute.parse(url)
    }
}
