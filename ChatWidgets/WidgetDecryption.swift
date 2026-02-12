import Foundation
import CryptoKit
import Security

/// Standalone decryption for extension targets. Mirrors AppGroupEncryption from main app.
/// Uses Security framework directly (no KeychainAccess dependency).
enum WidgetDecryption {
    private static let keychainService = "com.chrismarsh.chatark.appgroup-encryption"
    private static let keyName = "appgroup-symmetric-key"

    private static func readKey() -> SymmetricKey? {
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
