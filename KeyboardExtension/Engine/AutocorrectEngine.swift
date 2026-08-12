import UIKit

/// On-device, instant text intelligence: spell suggestions via UITextChecker,
/// auto-capitalization, and the double-space → ". " shortcut.
final class AutocorrectEngine {
    private let checker = UITextChecker()

    /// Up to 3 suggestions for the word currently being typed.
    func suggestions(forCurrentWordIn context: String, language: KeyboardLanguage) -> [String] {
        guard language.supportsSpellCheck else { return [] }
        guard let word = currentWord(in: context), word.count >= 2 else { return [] }

        let lang = language.localeIdentifier
        let nsWord = word as NSString
        let range = NSRange(location: 0, length: nsWord.length)

        var results: [String] = []

        // Completions while typing ("keybo" → "keyboard")
        if let completions = checker.completions(forPartialWordRange: range, in: word, language: lang) {
            results.append(contentsOf: completions.prefix(3))
        }

        // Corrections if the word is misspelled ("keybaord" → "keyboard")
        let misspelled = checker.rangeOfMisspelledWord(in: word, range: range, startingAt: 0, wrap: false, language: lang)
        if misspelled.location != NSNotFound,
           let guesses = checker.guesses(forWordRange: range, in: word, language: lang) {
            for guess in guesses where !results.contains(guess) {
                results.insert(guess, at: 0)
            }
        }

        // Preserve the user's capitalization for suggestions.
        if word.first?.isUppercase == true {
            results = results.map { $0.prefix(1).uppercased() + $0.dropFirst() }
        }

        var unique: [String] = []
        for s in results where !unique.contains(s) && s != word {
            unique.append(s)
        }
        return Array(unique.prefix(3))
    }

    /// The partial word immediately before the cursor, or nil at a word boundary.
    func currentWord(in context: String) -> String? {
        guard !context.isEmpty else { return nil }
        var word = ""
        for ch in context.reversed() {
            if ch.isLetter || ch == "'" {
                word.insert(ch, at: word.startIndex)
            } else {
                break
            }
        }
        return word.isEmpty ? nil : word
    }

    /// Should the next typed letter be auto-capitalized? True at the start of
    /// the document or after sentence-ending punctuation + space.
    func shouldAutoCapitalize(context: String?) -> Bool {
        guard let context, !context.isEmpty else { return true }
        let trimmedTrailing = context.reversed().drop { $0 == " " }
        guard let last = trimmedTrailing.first else { return true }
        if last == "\n" { return true }
        // Require at least one space after the punctuation ("word. " not "word.")
        let endedSentence = (last == "." || last == "!" || last == "?" || last == "।")
        return endedSentence && context.hasSuffix(" ")
    }

    /// True when a double-space should convert to ". " — i.e. the character
    /// before the just-typed space is a letter or digit followed by one space.
    func shouldApplyDoubleSpacePeriod(context: String?) -> Bool {
        guard let context, context.count >= 2, context.hasSuffix(" ") else { return false }
        let beforeSpace = context.dropLast()
        guard !beforeSpace.hasSuffix(" ") else { return false }
        guard let ch = beforeSpace.last else { return false }
        return ch.isLetter || ch.isNumber
    }
}
