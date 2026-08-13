import Foundation
import Security

/// Stores the Claude API key in the keychain. Both targets list the shared
/// keychain access group `$(AppIdentifierPrefix)com.yourteam.aiboard.shared`
/// FIRST in their entitlements, which makes it the default group for keychain
/// writes — so the app and the keyboard extension read the same item without
/// specifying `kSecAttrAccessGroup`, and the key never touches UserDefaults
/// or any other plaintext store.
enum KeychainHelper {
    private static let service = "com.yourteam.aiboard"
    private static let account = "claude-api-key"

    private static var query: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }

    static func saveAPIKey(_ key: String) {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        SecItemDelete(query as CFDictionary)
        guard !trimmed.isEmpty, let data = trimmed.data(using: .utf8) else { return }
        var attributes = query
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(attributes as CFDictionary, nil)
    }

    static func loadAPIKey() -> String? {
        var itemQuery = query
        itemQuery[kSecReturnData as String] = true
        itemQuery[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        guard SecItemCopyMatching(itemQuery as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8),
              !key.isEmpty else {
            return nil
        }
        return key
    }
}
