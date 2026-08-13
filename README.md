# AIBoard — Custom iPhone Keyboard with Clipboard + AI

A minimal, Android-style (Gboard-like) custom keyboard for iPhone, with:

- **Android key layout** — 4 rows, `?123` / comma / spacebar / period / return bottom row, shift + backspace on the third row, flat minimal design with light/dark mode.
- **Built-in clipboard manager** — the keyboard keeps a history of what you copy; tap the clipboard icon to browse, tap a clip to insert it, swipe to pin or delete.
- **Hybrid AI features**
  - Instant on-device: spelling suggestions (suggestion bar), auto-capitalization, double-space → period.
  - ✨ **Fix with AI**: one tap sends the current paragraph to the Claude API and replaces it with grammar-, spelling-, and punctuation-corrected text.
- **Speech-to-text** — iOS keyboards can't use the microphone, so the mic key opens the companion app, which transcribes your speech (Apple Speech framework, on-device where available) and hands the text back to the keyboard.
- **Multi-language** — English (QWERTY), Español, Français (AZERTY), Deutsch (QWERTZ), हिन्दी (Devanagari), with long-press accent/matra popups. The globe key cycles languages.

> **Note:** iOS does not allow third-party keyboards to reuse or extend the system keyboard. AIBoard is a full custom keyboard extension that recreates the familiar layout from scratch — that's the only way Apple permits it.

## Project structure

```
project.yml          XcodeGen manifest (generates AIBoard.xcodeproj)
AIBoard/             Companion app (SwiftUI): setup, clipboard history, dictation, settings
KeyboardExtension/   The keyboard itself (UIKit): views, layouts, engines
Shared/              Code compiled into both targets: storage, languages, Claude API client
```

## Build (on a Mac)

1. Install [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`
2. Clone this repo and run `xcodegen generate` in the repo root.
3. Open `AIBoard.xcodeproj` in Xcode.
4. In **Signing & Capabilities** for *both* targets (AIBoard and KeyboardExtension), select your development team. If Xcode complains about bundle IDs or the App Group, change `com.yourteam` in `project.yml` and `group.com.yourteam.aiboard` in `Shared/AppGroup.swift` to your own identifiers, then re-run `xcodegen generate`.
5. Build & run the **AIBoard** scheme — a physical iPhone is recommended (speech and keyboard behavior are limited in the simulator).

> If you'd rather not use XcodeGen: create an iOS App target named `AIBoard` and a Custom Keyboard Extension target named `KeyboardExtension` in Xcode, drag the matching source folders into each, add `Shared/` to both, enable the same App Group on both targets, add the `aiboard` URL scheme plus microphone/speech usage descriptions to the app's Info.plist, and set `RequestsOpenAccess = YES` in the extension's Info.plist.

## Enable the keyboard

1. iPhone **Settings → General → Keyboard → Keyboards → Add New Keyboard… → AIBoard**
2. Tap **AIBoard** in the list and enable **Allow Full Access** (required for the clipboard history and AI network calls).

## Set up AI

1. Open the AIBoard app → **Settings** tab.
2. Paste a Claude API key from [console.anthropic.com](https://console.anthropic.com) and tap **Test**, then **Save**.
3. In any app, type some text and tap the ✨ key — the current paragraph is corrected in place.

## Try everything

- Copy some text anywhere → open the keyboard → clipboard icon → your clip is there.
- Type `teh keybaord` → suggestions appear in the bar; tap one to accept.
- Type a sentence, double-tap space → `. ` is inserted and shift engages.
- Tap the mic key → the app opens → dictate → **Use in keyboard** → switch back → the text inserts itself.
- Tap the globe key to cycle English → Español → Français → Deutsch → हिन्दी. Long-press `e` for accents, or a Devanagari consonant for matras.

## Notes & limitations

- "Fix with AI" operates on the text the host app exposes near the cursor (usually the current paragraph) — iOS does not give keyboards the whole document.
- Hindi has no iOS spell-check dictionary, so the suggestion bar is inactive there.
- Without Full Access, typing works but clipboard history and AI features are disabled (the keyboard shows a hint).
- This code was authored off-Mac and not compiled here; if Xcode flags anything minor, it should be trivial to resolve.
