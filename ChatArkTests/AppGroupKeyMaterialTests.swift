import XCTest
import CryptoKit

/// Two things are covered here.
///
/// 1. `AppGroupKeyMaterial` -- the shape rules `AppGroupEncryption` applies to the key it
///    reads back out of the shared Keychain, and to the blobs it is asked to decrypt.
///
/// 2. The AES-GCM properties `AppGroupEncryption` *relies on* but does not itself
///    implement: that a combined box is nonce + ciphertext + tag, that a wrong key
///    fails, and that a single flipped bit fails. Those are asserted against CryptoKit
///    directly with a fixed key.
///
/// NOT covered, deliberately: `AppGroupEncryption.encrypt`/`decrypt` themselves. They
/// call `getOrCreateKey()`, which needs a real Keychain reachable through the shared
/// `keychain-access-groups` entitlement -- the exact thing !48 fixed, and the exact
/// thing a unit-test bundle does not have. Proving that path end-to-end needs the app
/// and an extension on a device; see the MR for what that would take.
final class AppGroupKeyMaterialTests: XCTestCase {

    // MARK: - Key material boundaries

    func testAcceptsExactly256BitKeyMaterial() {
        XCTAssertEqual(AppGroupKeyMaterial.keyByteCount, 32)
        XCTAssertTrue(AppGroupKeyMaterial.isValidKeyMaterial(Data(repeating: 0xAB, count: 32)))
    }

    /// One byte either side of 32 is rejected. A short read from the Keychain must cause
    /// a fresh key to be generated, never a truncated or stretched one to be used.
    func testRejectsKeyMaterialOffByOneInEitherDirection() {
        XCTAssertFalse(AppGroupKeyMaterial.isValidKeyMaterial(Data(repeating: 0xAB, count: 31)))
        XCTAssertFalse(AppGroupKeyMaterial.isValidKeyMaterial(Data(repeating: 0xAB, count: 33)))
    }

    /// A 16-byte blob is a perfectly valid AES-128 key. It must still be rejected --
    /// silently accepting it would downgrade the cipher with nothing in the logs.
    func testRejectsShorterButOtherwiseValidAESKeyLengths() {
        for count in [16, 24] {
            XCTAssertFalse(AppGroupKeyMaterial.isValidKeyMaterial(Data(repeating: 0xAB, count: count)),
                           "\(count)-byte key material must not be accepted")
        }
    }

    func testRejectsEmptyKeyMaterial() {
        XCTAssertFalse(AppGroupKeyMaterial.isValidKeyMaterial(Data()))
    }

    // MARK: - Combined-box boundaries

    func testCombinedMinimumIsNoncePlusTag() {
        XCTAssertEqual(AppGroupKeyMaterial.nonceByteCount, 12)
        XCTAssertEqual(AppGroupKeyMaterial.tagByteCount, 16)
        XCTAssertEqual(AppGroupKeyMaterial.combinedMinimumByteCount, 28)
    }

    func testRejectsBlobsShorterThanTheMinimumBox() {
        XCTAssertFalse(AppGroupKeyMaterial.isPlausibleCombinedBox(Data()))
        XCTAssertFalse(AppGroupKeyMaterial.isPlausibleCombinedBox(Data(repeating: 0, count: 27)))
        XCTAssertTrue(AppGroupKeyMaterial.isPlausibleCombinedBox(Data(repeating: 0, count: 28)))
    }

    /// The declared minimum must match what CryptoKit actually enforces, otherwise the
    /// cheap pre-check in `decrypt` either does nothing or rejects valid boxes.
    func testDeclaredMinimumMatchesCryptoKit() throws {
        let key = SymmetricKey(data: Data(repeating: 0x01, count: 32))
        let combined = try XCTUnwrap(AES.GCM.seal(Data(), using: key).combined)

        XCTAssertEqual(combined.count, AppGroupKeyMaterial.combinedMinimumByteCount)
        XCTAssertThrowsError(try AES.GCM.SealedBox(combined: combined.dropLast()))
    }

    // MARK: - Properties AppGroupEncryption depends on

    func testRoundTripsWithAFixedKey() throws {
        let key = SymmetricKey(data: Data(repeating: 0x02, count: 32))
        let plaintext = Data("eyebrow-raising secret".utf8)

        let combined = try XCTUnwrap(AES.GCM.seal(plaintext, using: key).combined)
        let opened = try AES.GCM.open(AES.GCM.SealedBox(combined: combined), using: key)

        XCTAssertEqual(opened, plaintext)
        XCTAssertEqual(combined.count, plaintext.count + AppGroupKeyMaterial.combinedMinimumByteCount)
    }

    func testCiphertextDoesNotContainThePlaintext() throws {
        let key = SymmetricKey(data: Data(repeating: 0x03, count: 32))
        let plaintext = Data("AAAAAAAAAAAAAAAAAAAA".utf8)
        let combined = try XCTUnwrap(AES.GCM.seal(plaintext, using: key).combined)

        XCTAssertNil(combined.range(of: plaintext))
    }

    func testADifferentKeyCannotOpenTheBox() throws {
        let key = SymmetricKey(data: Data(repeating: 0x04, count: 32))
        let otherKey = SymmetricKey(data: Data(repeating: 0x05, count: 32))
        let combined = try XCTUnwrap(AES.GCM.seal(Data("payload".utf8), using: key).combined)

        XCTAssertThrowsError(try AES.GCM.open(AES.GCM.SealedBox(combined: combined), using: otherKey))
    }

    /// Authentication, not just confidentiality: a single flipped bit anywhere in the
    /// box must fail to open. This is why `decrypt` returning nil is a security signal
    /// and not merely a parse failure.
    func testASingleFlippedBitFailsAuthentication() throws {
        let key = SymmetricKey(data: Data(repeating: 0x06, count: 32))
        let combined = try XCTUnwrap(AES.GCM.seal(Data("payload".utf8), using: key).combined)

        for offset in [0, combined.count / 2, combined.count - 1] {
            var tampered = combined
            tampered[tampered.startIndex + offset] ^= 0x01
            XCTAssertThrowsError(try AES.GCM.open(AES.GCM.SealedBox(combined: tampered), using: key),
                                 "tampering at byte \(offset) was not detected")
        }
    }

    func testEveryEncryptionUsesAFreshNonce() throws {
        let key = SymmetricKey(data: Data(repeating: 0x07, count: 32))
        let plaintext = Data("identical every time".utf8)

        let first = try XCTUnwrap(AES.GCM.seal(plaintext, using: key).combined)
        let second = try XCTUnwrap(AES.GCM.seal(plaintext, using: key).combined)

        XCTAssertNotEqual(first, second, "identical plaintext produced an identical box -- nonce reuse")
        XCTAssertNotEqual(first.prefix(AppGroupKeyMaterial.nonceByteCount),
                          second.prefix(AppGroupKeyMaterial.nonceByteCount))
    }
}
