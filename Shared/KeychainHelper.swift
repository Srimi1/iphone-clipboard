import Foundation
import Security

/// Stores the Claude API key. Uses the keychain when available; the keyboard
/// extension can read it because both targets share the App Group-backed
/// fallback in shared UserDefaults if keychain sharing isn't configured.
///
/// Note: for keychain access from the extension you'd normally add a shared
/// keychain access group. To keep setup simple this helper writes to both the
/// local keychain and the App Group defaults, and reads keychain-first.
enum KeychainHelper {
    private static let service = "com.yourteam.aiboard"
    private static let account = "claude-api-key"

    static func saveAPIKey(_ key: String) {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        AppGroup.defaults.set(trimmed, forKey: AppGroup.Key.apiKeyFallback)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)
        guard !trimmed.isEmpty, let data = trimmed.data(using: .utf8) else { return }
        var attributes = query
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(attributes as CFDictionary, nil)
    }

    static func loadAPIKey() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        if SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
           let data = result as? Data,
           let key = String(data: data, encoding: .utf8),
           !key.isEmpty {
            return key
        }
        let fallback = AppGroup.defaults.string(forKey: AppGroup.Key.apiKeyFallback)
        return (fallback?.isEmpty == false) ? fallback : nil
    }
}
