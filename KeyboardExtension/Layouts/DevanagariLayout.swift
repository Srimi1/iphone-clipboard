import Foundation

/// Hindi (Devanagari) layout, arranged in the familiar 4-row phone-keyboard
/// shape.
///
/// Devanagari is caseless, so there is no shift layer to hold the aspirated and
/// retroflex consonants the way a physical InScript keyboard does. They live on
/// long-press instead: each consonant key offers its aspirate/retroflex
/// partners first, then that consonant combined with each matra (vowel sign).
/// The halant (्) is among the matras, so conjuncts such as क्ष are typed as
/// क + ् + ष.
enum DevanagariLayout {

    /// Most frequent matras offered on consonant long-press, capped so the
    /// popup (base + partners + matras) fits the narrowest supported iPhone.
    private static let matras = ["ा", "ि", "ी", "ु", "ू", "े", "ो", "्"]

    /// `extras` are related letters (aspirates, retroflexes, sibilants) that
    /// have no key of their own; they precede the matras so they are one short
    /// slide away.
    private static func consonant(_ c: String, _ extras: String...) -> Key {
        .char(c, variants: extras + matras.map { c + $0 })
    }

    static let layout = KeyboardLayout(rows: [
        [
            .char("ौ", variants: ["औ"]),
            .char("ै", variants: ["ऐ"]),
            .char("ा", variants: ["आ"]),
            .char("ी", variants: ["ई"]),
            .char("ू", variants: ["ऊ"]),
            consonant("ब", "भ"),
            consonant("ह"),
            consonant("ग", "घ"),
            consonant("द", "ध", "ड", "ढ"),
            consonant("ज", "झ"),
        ],
        [
            .char("ो", variants: ["ओ"]),
            .char("े", variants: ["ए"]),
            .char("्", variants: ["अ"]),
            .char("ि", variants: ["इ"]),
            .char("ु", variants: ["उ"]),
            consonant("प", "फ"),
            consonant("र"),
            consonant("क", "ख"),
            consonant("त", "थ", "ट", "ठ"),
            consonant("च", "छ"),
        ],
        KeyboardLayout.thirdRow([
            .char("ं", variants: ["ँ", "ः", "ऋ"]),
            consonant("म"),
            consonant("न", "ण"),
            consonant("व"),
            consonant("ल"),
            consonant("स"),
            consonant("य", "श", "ष"),
        ],
        // Devanagari has no case, so the shift slot would be inert — give it
        // the danda (Hindi full stop) instead.
        leading: .character("।"),
        leadingVariants: ["॥", "ऽ", "₹"]),
        KeyboardLayout.bottomRow(),
    ])
}
