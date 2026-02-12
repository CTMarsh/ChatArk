import Foundation
import CryptoKit
import os.log
@preconcurrency import KeychainAccess

/// Encrypts/decrypts data stored in App Group UserDefaults using AES-GCM.
/// The symmetric key is stored in the shared Keychain group.
enum AppGroupEncryption {
    private static let keychainService = "com.chrismarsh.chatark.appgroup-encryption"
    private static let keyName = "appgroup-symmetric-key"
    private static let logger = Logger(subsystem: "com.chrismarsh.chatark", category: "AppGroupEncryption")

    private static var keychain: Keychain {
        Keychain(service: keychainService)
            .accessibility(.afterFirstUnlockThisDeviceOnly)
    }

    // MARK: - Key Management

    private static func getOrCreateKey() -> SymmetricKey {
        if let existingKeyData = try? keychain.getData(keyName),
           existingKeyData.count == 32 {
            return SymmetricKey(data: existingKeyData)
        }

        let newKey = SymmetricKey(size: .bits256)
        let keyData = newKey.withUnsafeBytes { Data($0) }
        do {
            try keychain.set(keyData, key: keyName)
        } catch {
            logger.error("Failed to store encryption key in Keychain: \(error.localizedDescription, privacy: .public)")
        }
        return newKey
    }

    // MARK: - Encrypt / Decrypt

    static func encrypt(_ data: Data) -> Data? {
        let key = getOrCreateKey()
        do {
            let sealedBox = try AES.GCM.seal(data, using: key)
            guard let combined = sealedBox.combined else {
                logger.error("AES-GCM seal succeeded but combined representation is nil")
                return nil
            }
            return combined
        } catch {
            logger.error("AES-GCM encryption failed: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    static func decrypt(_ data: Data) -> Data? {
        let key = getOrCreateKey()
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: data)
            return try AES.GCM.open(sealedBox, using: key)
        } catch {
            logger.error("AES-GCM decryption failed: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    // MARK: - Convenience: String

    static func encryptString(_ string: String) -> Data? {
        guard let data = string.data(using: .utf8) else { return nil }
        return encrypt(data)
    }

    static func decryptString(_ data: Data) -> String? {
        guard let decrypted = decrypt(data) else { return nil }
        return String(data: decrypted, encoding: .utf8)
    }
}
