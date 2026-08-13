import Foundation

/// Letter layouts for the Latin-script languages, laid out Android (Gboard) style:
/// 3 letter rows + the shared bottom row.
enum LatinLayouts {

    // MARK: English — QWERTY

    static let english = KeyboardLayout(rows: [
        [
            .char("q"), .char("w"), .char("e", variants: ["è", "é", "ê", "ë", "ē"]),
            .char("r"), .char("t"), .char("y"),
            .char("u", variants: ["û", "ü", "ù", "ú"]),
            .char("i", variants: ["î", "ï", "í", "ì"]),
            .char("o", variants: ["ô", "ö", "ò", "ó", "ø"]),
            .char("p"),
        ],
        [
            .char("a", variants: ["à", "á", "â", "ä", "æ", "ã", "å"]),
            .char("s", variants: ["ß"]), .char("d"), .char("f"), .char("g"),
            .char("h"), .char("j"), .char("k"), .char("l"),
        ],
        KeyboardLayout.thirdRow([
            .char("z"), .char("x"),
            .char("c", variants: ["ç"]),
            .char("v"), .char("b"),
            .char("n", variants: ["ñ"]),
            .char("m"),
        ]),
        KeyboardLayout.bottomRow(),
    ])

    // MARK: Spanish — QWERTY + ñ

    static let spanish = KeyboardLayout(rows: [
        [
            .char("q"), .char("w"), .char("e", variants: ["é", "è", "ê", "ë"]),
            .char("r"), .char("t"), .char("y"),
            .char("u", variants: ["ú", "ü", "ù", "û"]),
            .char("i", variants: ["í", "ì", "î", "ï"]),
            .char("o", variants: ["ó", "ò", "ô", "ö"]),
            .char("p"),
        ],
        [
            .char("a", variants: ["á", "à", "â", "ä"]),
            .char("s"), .char("d"), .char("f"), .char("g"),
            .char("h"), .char("j"), .char("k"), .char("l"), .char("ñ"),
        ],
        KeyboardLayout.thirdRow([
            .char("z"), .char("x"), .char("c", variants: ["ç"]),
            .char("v"), .char("b"), .char("n"), .char("m"),
        ]),
        KeyboardLayout.bottomRow(),
    ])

    // MARK: French — AZERTY

    static let french = KeyboardLayout(rows: [
        [
            .char("a", variants: ["à", "â", "æ", "á", "ä"]),
            .char("z"),
            .char("e", variants: ["é", "è", "ê", "ë"]),
            .char("r"), .char("t"),
            .char("y", variants: ["ÿ"]),
            .char("u", variants: ["ù", "û", "ü", "ú"]),
            .char("i", variants: ["î", "ï", "í", "ì"]),
            .char("o", variants: ["ô", "œ", "ö", "ó"]),
            .char("p"),
        ],
        [
            .char("q"), .char("s"), .char("d"), .char("f"), .char("g"),
            .char("h"), .char("j"), .char("k"), .char("l"), .char("m"),
        ],
        KeyboardLayout.thirdRow([
            .char("w"), .char("x"),
            .char("c", variants: ["ç"]),
            .char("v"), .char("b"), .char("n"),
        ]),
        KeyboardLayout.bottomRow(),
    ])

    // MARK: German — QWERTZ

    static let german = KeyboardLayout(rows: [
        [
            .char("q"), .char("w"),
            .char("e", variants: ["é", "è", "ê", "ë"]),
            .char("r"), .char("t"), .char("z"),
            .char("u", variants: ["ü", "ù", "ú", "û"]),
            .char("i"),
            .char("o", variants: ["ö", "ô", "ò", "ó"]),
            .char("p"),
        ],
        [
            .char("a", variants: ["ä", "à", "á", "â"]),
            .char("s", variants: ["ß"]),
            .char("d"), .char("f"), .char("g"),
            .char("h"), .char("j"), .char("k"), .char("l"),
        ],
        KeyboardLayout.thirdRow([
            .char("y"), .char("x"), .char("c"),
            .char("v"), .char("b"), .char("n"), .char("m"),
        ]),
        KeyboardLayout.bottomRow(),
    ])
}
