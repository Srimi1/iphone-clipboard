import Foundation

enum KeyboardLanguage: String, Codable, CaseIterable, Identifiable {
    case english = "en"
    case spanish = "es"
    case french = "fr"
    case german = "de"
    case hindi = "hi"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english: return "English"
        case .spanish: return "Español"
        case .french: return "Français"
        case .german: return "Deutsch"
        case .hindi: return "हिन्दी"
        }
    }

    /// Locale identifier used by UITextChecker / SFSpeechRecognizer.
    var localeIdentifier: String {
        switch self {
        case .english: return "en_US"
        case .spanish: return "es_ES"
        case .french: return "fr_FR"
        case .german: return "de_DE"
        case .hindi: return "hi_IN"
        }
    }

    /// iOS has no built-in Hindi spell checking, so autocorrect is disabled there.
    var supportsSpellCheck: Bool { self != .hindi }
}

/// Current + enabled languages, shared through App Group defaults.
final class LanguageManager {
    static let shared = LanguageManager()
    private init() {}

    var current: KeyboardLanguage {
        get {
            let raw = AppGroup.defaults.string(forKey: AppGroup.Key.currentLanguage) ?? "en"
            return KeyboardLanguage(rawValue: raw) ?? .english
        }
        set {
            AppGroup.defaults.set(newValue.rawValue, forKey: AppGroup.Key.currentLanguage)
        }
    }

    var enabled: [KeyboardLanguage] {
        get {
            guard let raw = AppGroup.defaults.stringArray(forKey: AppGroup.Key.enabledLanguages) else {
                return KeyboardLanguage.allCases
            }
            let langs = raw.compactMap(KeyboardLanguage.init(rawValue:))
            return langs.isEmpty ? [.english] : langs
        }
        set {
            let value = newValue.isEmpty ? [KeyboardLanguage.english] : newValue
            AppGroup.defaults.set(value.map(\.rawValue), forKey: AppGroup.Key.enabledLanguages)
            // Never leave the keyboard on a language that was just disabled.
            if !value.contains(current) {
                current = value[0]
            }
        }
    }

    /// Advances to the next enabled language and returns it.
    @discardableResult
    func cycle() -> KeyboardLanguage {
        let langs = enabled
        guard let index = langs.firstIndex(of: current) else {
            current = langs[0]
            return langs[0]
        }
        let next = langs[(index + 1) % langs.count]
        current = next
        return next
    }
}
