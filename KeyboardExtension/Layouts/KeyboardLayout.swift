import Foundation
import CoreGraphics

/// What a key does when tapped.
enum KeyAction: Equatable {
    case character(String)   // inserts text (respects shift for letters)
    case shift
    case backspace
    case space
    case returnKey
    case switchToSymbols     // "?123"
    case switchToLetters     // "ABC"
    case switchToSymbolsAlt  // "=\<" second symbols page
    case globe               // cycle language
}

enum ShiftState {
    case off, on, capsLock
}

struct Key {
    let action: KeyAction
    /// Relative width; a plain letter key is 1.0. Android-style: shift/backspace 1.5, space ~4.
    let widthMultiplier: CGFloat
    /// Long-press accent variants (already in lowercase; shifted at render time).
    let variants: [String]

    init(_ action: KeyAction, width: CGFloat = 1.0, variants: [String] = []) {
        self.action = action
        self.widthMultiplier = width
        self.variants = variants
    }

    static func char(_ s: String, variants: [String] = []) -> Key {
        Key(.character(s), variants: variants)
    }
}

struct KeyboardLayout {
    /// Rows of letter keys (typically 3 rows: 10 / 9 / 7-with-shift-and-backspace).
    let rows: [[Key]]

    /// Builds the standard Android-style bottom row:
    /// [?123] [,] [space] [.] [return]
    static func bottomRow(symbolsKey: KeyAction = .switchToSymbols) -> [Key] {
        [
            Key(symbolsKey, width: 1.5),
            Key.char(",", variants: ["!", "?", ";", ":"]),
            Key(.space, width: 4.0),
            Key.char(".", variants: ["?", "!", "…", "-", "'", "\""]),
            Key(.returnKey, width: 1.5),
        ]
    }

    /// Wraps a middle letter row with shift and backspace, Android style.
    static func thirdRow(_ letters: [Key]) -> [Key] {
        [Key(.shift, width: 1.5)] + letters + [Key(.backspace, width: 1.5)]
    }
}

/// Symbols pages shared by all Latin layouts (Android ?123 arrangement).
enum SymbolLayouts {
    static let page1 = KeyboardLayout(rows: [
        ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"].map { Key.char($0) },
        ["@", "#", "$", "_", "&", "-", "+", "(", ")", "/"].map { Key.char($0) },
        [Key(.switchToSymbolsAlt, width: 1.5)]
            + ["*", "\"", "'", ":", ";", "!", "?"].map { Key.char($0) }
            + [Key(.backspace, width: 1.5)],
        KeyboardLayout.bottomRow(symbolsKey: .switchToLetters),
    ])

    static let page2 = KeyboardLayout(rows: [
        ["~", "`", "|", "•", "√", "π", "÷", "×", "¶", "∆"].map { Key.char($0) },
        ["£", "€", "¥", "¢", "^", "°", "=", "{", "}", "\\"].map { Key.char($0) },
        [Key(.switchToSymbols, width: 1.5)]
            + ["%", "©", "®", "™", "✓", "[", "]"].map { Key.char($0) }
            + [Key(.backspace, width: 1.5)],
        KeyboardLayout.bottomRow(symbolsKey: .switchToLetters),
    ])
}
