import Foundation
import CryptoKit
import Security

/// Standalone decryption for ShareExtension. Mirrors AppGroupEncryption from main app.
enum ShareDecryption {
    private static let keychainService = "com.chrismarsh.chatark.appgroup-encryption"
    private static let keyName = "appgroup-symmetric-key"

    private static func readKey() -> SymmetricKey? {
        // The main app (AppGroupEncryption) writes this key with no explicit
        // kSecAttrAccessGroup, so it lands in the app's default keychain group —
        // the first (and only) entry of its keychain-access-groups entitlement,
        // $(AppIdentifierPrefix)com.chrismarsh.chatark. This extension shares that
        // same group via its own keychain-access-groups entitlement, so an
        // access-group-unscoped query searches all entitled groups and resolves
        // to the shared item. The query is intentionally left unscoped to mirror
        // the unscoped writer; do NOT hardcode a kSecAttrAccessGroup here
        // ($(AppIdentifierPrefix) cannot be expanded at runtime, and a literal
        // team-prefixed group would drift from the writer).
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keyName,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data, data.count == 32 else {
            return nil
        }
        return SymmetricKey(data: data)
    }

    static func decrypt(_ data: Data) -> Data? {
        guard let key = readKey(),
              let sealedBox = try? AES.GCM.SealedBox(combined: data),
              let decrypted = try? AES.GCM.open(sealedBox, using: key) else {
            return nil
        }
        return decrypted
    }

    static func decryptString(_ data: Data) -> String? {
        guard let decrypted = decrypt(data) else { return nil }
        return String(data: decrypted, encoding: .utf8)
    }
}
