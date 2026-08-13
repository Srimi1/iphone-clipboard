import Foundation

/// Central access point for everything shared between the app and the keyboard extension.
enum AppGroup {
    /// Replace with your own App Group identifier if you change the bundle IDs.
    static let identifier = "group.com.yourteam.aiboard"

    static var defaults: UserDefaults {
        guard let suite = UserDefaults(suiteName: identifier) else {
            // Misconfigured App Group entitlement — fail loudly in development
            // instead of silently writing to the wrong defaults domain.
            assertionFailure("App Group \(identifier) is not configured; check the entitlements on both targets.")
            return .standard
        }
        return suite
    }

    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
    }

    // MARK: - Shared keys

    enum Key {
        static let pendingTranscription = "pendingTranscription"
        static let currentLanguage = "currentLanguage"
        static let enabledLanguages = "enabledLanguages"
        static let lastPasteboardChangeCount = "lastPasteboardChangeCount"
    }

    // MARK: - Pending transcription round-trip

    static func setPendingTranscription(_ text: String) {
        defaults.set(text, forKey: Key.pendingTranscription)
    }

    /// Returns the pending transcription (if any) and clears it.
    static func consumePendingTranscription() -> String? {
        guard let text = defaults.string(forKey: Key.pendingTranscription), !text.isEmpty else {
            return nil
        }
        defaults.removeObject(forKey: Key.pendingTranscription)
        return text
    }
}
