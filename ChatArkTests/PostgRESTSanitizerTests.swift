import XCTest

/// `PostgRESTSanitizer` escapes the metacharacters of a PostgREST filter expression.
/// It matters because `SearchService` and `PresenceService` interpolate user input
/// straight into an `.or(...)` filter:
///
///     .or("username.ilike.%\(sanitize(q))%,display_name.ilike.%\(sanitize(q))%")
///
/// An unescaped `,` or `.` there does not just widen a search — it appends a whole new
/// filter clause to the query. These tests pin the escaping rules.
///
/// Expected values use Swift raw strings (`#"\."#`) so a backslash in an assertion is
/// one backslash, not a puzzle.
final class PostgRESTSanitizerTests: XCTestCase {

    // MARK: - Each metacharacter

    func testEscapesDot() {
        XCTAssertEqual(PostgRESTSanitizer.sanitize("."), #"\."#)
    }

    func testEscapesPercent() {
        XCTAssertEqual(PostgRESTSanitizer.sanitize("%"), #"\%"#)
    }

    func testEscapesAsterisk() {
        XCTAssertEqual(PostgRESTSanitizer.sanitize("*"), #"\*"#)
    }

    func testEscapesParentheses() {
        XCTAssertEqual(PostgRESTSanitizer.sanitize("("), #"\("#)
        XCTAssertEqual(PostgRESTSanitizer.sanitize(")"), #"\)"#)
    }

    func testEscapesComma() {
        XCTAssertEqual(PostgRESTSanitizer.sanitize(","), #"\,"#)
    }

    func testEscapesBackslash() {
        XCTAssertEqual(PostgRESTSanitizer.sanitize(#"\"#), #"\\"#)
    }

    // MARK: - Ordering

    /// The backslash must be escaped FIRST, otherwise the backslashes introduced while
    /// escaping `.` would themselves be escaped on a later pass and the payload would
    /// come apart. Input `\.` (backslash, dot) must become `\` + `\.` = `\\.`.
    func testBackslashIsEscapedBeforeTheOtherMetacharacters() {
        XCTAssertEqual(PostgRESTSanitizer.sanitize(#"\."#), #"\\\."#)
    }

    // MARK: - The injection this exists to stop

    /// A search term that tries to close the `ilike` clause and append its own filter —
    /// the shape that would let an ordinary user select on an admin column.
    func testFilterInjectionPayloadIsNeutralised() {
        let payload = "alice,is_platform_admin.eq.true"
        let sanitized = PostgRESTSanitizer.sanitize(payload)

        XCTAssertEqual(sanitized, #"alice\,is_platform_admin\.eq\.true"#)
        // No bare separator survives: every `,` and `.` is preceded by a backslash.
        XCTAssertFalse(containsUnescaped(",", in: sanitized))
        XCTAssertFalse(containsUnescaped(".", in: sanitized))
    }

    func testWildcardPayloadIsNeutralised() {
        XCTAssertEqual(PostgRESTSanitizer.sanitize("%%%"), #"\%\%\%"#)
    }

    func testNestedFilterPayloadIsNeutralised() {
        XCTAssertEqual(PostgRESTSanitizer.sanitize("or(a.eq.1)"), #"or\(a\.eq\.1\)"#)
    }

    // MARK: - Pass-through

    func testEmptyStringIsUnchanged() {
        XCTAssertEqual(PostgRESTSanitizer.sanitize(""), "")
    }

    func testOrdinaryTermIsUnchanged() {
        XCTAssertEqual(PostgRESTSanitizer.sanitize("alice"), "alice")
    }

    func testUnicodeIsPreservedByteForByte() {
        XCTAssertEqual(PostgRESTSanitizer.sanitize("héllo 😀 名前"), "héllo 😀 名前")
    }

    /// `&` is deliberately NOT escaped here — the Supabase Swift SDK builds the query
    /// through `URLComponents`/`URLQueryItem`, which percent-encodes it to `%26` at the
    /// transport layer. This test exists so that if anyone ever swaps that transport for
    /// hand-built query strings, the assumption fails loudly instead of silently.
    func testAmpersandIsIntentionallyNotEscaped() {
        XCTAssertEqual(PostgRESTSanitizer.sanitize("a&b"), "a&b")
    }

    /// KNOWN GAP, deliberately pinned rather than hidden: `_` is PostgreSQL's
    /// single-character `LIKE`/`ILIKE` wildcard and is not escaped. It cannot break out
    /// of the clause the way `,` or `.` can — it only widens the match — but a term of
    /// underscores matches far more rows than the user typed. If that is ever tightened,
    /// this test is the one that should be updated on purpose.
    func testUnderscoreIsNotEscapedDocumentsKnownGap() {
        XCTAssertEqual(PostgRESTSanitizer.sanitize("a_b"), "a_b")
    }

    // MARK: - Not idempotent

    /// Sanitizing twice double-escapes. Callers must sanitize exactly once, at the point
    /// of interpolation — the current call sites do. This pins that so a future
    /// "defensive" second call is caught as a behaviour change, not shipped as a no-op.
    func testSanitizeIsNotIdempotent() {
        let once = PostgRESTSanitizer.sanitize(".")
        let twice = PostgRESTSanitizer.sanitize(once)
        XCTAssertEqual(once, #"\."#)
        XCTAssertEqual(twice, #"\\\."#)
        XCTAssertNotEqual(once, twice)
    }

    // MARK: - Helper

    /// True if `needle` appears at least once without a backslash immediately before it.
    private func containsUnescaped(_ needle: Character, in haystack: String) -> Bool {
        var previous: Character?
        for character in haystack {
            if character == needle && previous != "\\" { return true }
            previous = character
        }
        return false
    }
}
