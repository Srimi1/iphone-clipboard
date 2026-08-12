import Foundation

/// Hindi (Devanagari) layout, arranged in the familiar 4-row phone-keyboard
/// shape. Long-press on consonants exposes the matras (vowel signs) and
/// related conjunct forms; the halant (्) lives on long-press too.
enum DevanagariLayout {

    /// Most frequent matras offered on consonant long-press, capped so the
    /// popup (base + variants) fits the narrowest supported iPhone.
    private static let matras = ["ा", "ि", "ी", "ु", "ू", "े", "ो", "्"]

    private static func consonant(_ c: String) -> Key {
        .char(c, variants: matras.map { c + $0 })
    }

    static let layout = KeyboardLayout(rows: [
        [
            .char("ौ", variants: ["औ"]),
            .char("ै", variants: ["ऐ"]),
            .char("ा", variants: ["आ"]),
            .char("ी", variants: ["ई"]),
            .char("ू", variants: ["ऊ"]),
            consonant("ब"),
            consonant("ह"),
            consonant("ग"),
            consonant("द"),
            consonant("ज"),
        ],
        [
            .char("ो", variants: ["ओ"]),
            .char("े", variants: ["ए"]),
            .char("्", variants: ["अ"]),
            .char("ि", variants: ["इ"]),
            .char("ु", variants: ["उ"]),
            consonant("प"),
            consonant("र"),
            consonant("क"),
            consonant("त"),
            consonant("च"),
        ],
        KeyboardLayout.thirdRow([
            .char("ं", variants: ["ँ", "ः", "ऋ"]),
            consonant("म"),
            consonant("न"),
            consonant("व"),
            consonant("ल"),
            consonant("स"),
            .char("य", variants: ["श", "ष", "ज्ञ", "त्र", "क्ष"]),
        ]),
        KeyboardLayout.bottomRow(),
    ])

}
