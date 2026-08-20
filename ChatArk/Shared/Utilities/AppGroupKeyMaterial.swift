import Foundation

/// Shape rules for the AES-GCM material `AppGroupEncryption` handles.
///
/// Split out of `AppGroupEncryption` so it carries no Keychain dependency and can be
/// unit-tested: the encrypt/decrypt path itself needs a real Keychain *and* the shared
/// `keychain-access-groups` entitlement (the thing !48 fixed), neither of which a unit
/// test bundle has. What can be tested without a device is the boundary arithmetic —
/// which is where a silent downgrade would hide.
enum AppGroupKeyMaterial {

    /// AES-256. A key of any other length is rejected and a fresh one generated,
    /// rather than being stretched, truncated, or used to build a weaker cipher.
    static let keyByteCount = 32

    /// `AES.GCM.SealedBox.combined` layout: 12-byte nonce ‖ ciphertext ‖ 16-byte tag.
    static let nonceByteCount = 12
    static let tagByteCount = 16

    /// The smallest possible combined box — nonce + tag, with zero-length ciphertext.
    static var combinedMinimumByteCount: Int { nonceByteCount + tagByteCount }

    /// True only for exactly-256-bit key material. Used to decide whether the blob
    /// found in the Keychain is usable or must be regenerated.
    static func isValidKeyMaterial(_ data: Data) -> Bool {
        data.count == keyByteCount
    }

    /// Cheap structural pre-check on a stored blob. Anything shorter than
    /// nonce + tag cannot be a sealed box, whatever its contents.
    static func isPlausibleCombinedBox(_ data: Data) -> Bool {
        data.count >= combinedMinimumByteCount
    }
}
