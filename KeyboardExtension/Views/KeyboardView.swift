import UIKit

/// Flat, minimal, Gboard-like palette that adapts to light/dark mode.
enum KeyboardTheme {
    static let background = UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(white: 0.12, alpha: 1)
            : UIColor(red: 0.93, green: 0.94, blue: 0.95, alpha: 1)
    }
    static let keyBackground = UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(white: 0.25, alpha: 1) : .white
    }
    static let specialKeyBackground = UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(white: 0.18, alpha: 1)
            : UIColor(red: 0.80, green: 0.82, blue: 0.85, alpha: 1)
    }
    static let popupBackground = UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(white: 0.30, alpha: 1) : .white
    }
    static let keyText = UIColor { trait in
        trait.userInterfaceStyle == .dark ? .white : UIColor(white: 0.13, alpha: 1)
    }
    static let secondaryText = UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(white: 0.7, alpha: 1) : UIColor(white: 0.4, alpha: 1)
    }
    static let accent = UIColor.systemBlue
}

protocol KeyboardViewDelegate: AnyObject {
    /// A key resolved to concrete text to insert.
    func keyboardView(_ view: KeyboardView, didProduceText text: String)
    func keyboardViewDidTapBackspace(_ view: KeyboardView)
    func keyboardViewDidTapReturn(_ view: KeyboardView)
    func keyboardViewDidTapSpace(_ view: KeyboardView)
    func keyboardViewDidTapGlobe(_ view: KeyboardView)
    /// Asked before rendering letters: should shift auto-engage (start of sentence)?
    func keyboardViewShouldAutoCapitalize(_ view: KeyboardView) -> Bool
}

private enum KeyboardPage {
    case letters, symbols, symbolsAlt
}

/// The key grid: 3 letter rows + bottom row, page switching, shift handling,
/// tap previews, and long-press accent popups.
final class KeyboardView: UIView, KeyButtonDelegate {
    weak var delegate: KeyboardViewDelegate?

    private var page: KeyboardPage = .letters
    private(set) var shiftState: ShiftState = .off
    private var lastShiftTap: Date?
    private var currentLanguage: KeyboardLanguage = .english

    private let rowsStack = UIStackView()
    private var keyButtons: [KeyButton] = []
    private let popup = KeyPopupView()
    private weak var popupOwner: KeyButton?

    // MARK: - Setup

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = KeyboardTheme.background
        rowsStack.axis = .vertical
        rowsStack.distribution = .fillEqually
        rowsStack.spacing = 8
        rowsStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(rowsStack)
        NSLayoutConstraint.activate([
            rowsStack.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            rowsStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),
            rowsStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 3),
            rowsStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -3),
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    func configure(language: KeyboardLanguage) {
        currentLanguage = language
        page = .letters
        shiftState = .off
        rebuild()
    }

    private var activeLayout: KeyboardLayout {
        switch page {
        case .symbols: return SymbolLayouts.page1
        case .symbolsAlt: return SymbolLayouts.page2
        case .letters:
            switch currentLanguage {
            case .english: return LatinLayouts.english
            case .spanish: return LatinLayouts.spanish
            case .french: return LatinLayouts.french
            case .german: return LatinLayouts.german
            case .hindi: return DevanagariLayout.layout
            }
        }
    }

    private func rebuild() {
        rowsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        keyButtons = []

        for row in activeLayout.rows {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.spacing = 5
            rowStack.distribution = .fill

            var previousUnitKey: KeyButton?
            for key in row {
                let button = KeyButton(key: key)
                button.delegate = self
                keyButtons.append(button)
                rowStack.addArrangedSubview(button)

                if key.widthMultiplier == 1.0 {
                    if let reference = previousUnitKey {
                        button.widthAnchor.constraint(equalTo: reference.widthAnchor).isActive = true
                    }
                    previousUnitKey = button
                }
            }
            // Non-unit keys sized relative to the first unit key in the row.
            if let unit = row.firstIndex(where: { $0.widthMultiplier == 1.0 }) {
                let unitButton = rowStack.arrangedSubviews[unit] as! KeyButton
                for (i, key) in row.enumerated() where key.widthMultiplier != 1.0 {
                    let button = rowStack.arrangedSubviews[i] as! KeyButton
                    button.widthAnchor.constraint(equalTo: unitButton.widthAnchor,
                                                  multiplier: key.widthMultiplier).isActive = true
                }
            }

            // Center rows that have fewer keys (e.g. the 9-key home row).
            let container = UIView()
            rowStack.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(rowStack)
            NSLayoutConstraint.activate([
                rowStack.topAnchor.constraint(equalTo: container.topAnchor),
                rowStack.bottomAnchor.constraint(equalTo: container.bottomAnchor),
                rowStack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                rowStack.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor),
            ])
            // Full-width rows (10 keys or with wide keys) stretch edge to edge.
            if row.count >= 10 || row.contains(where: { $0.widthMultiplier > 1.0 }) {
                rowStack.leadingAnchor.constraint(equalTo: container.leadingAnchor).isActive = true
                rowStack.trailingAnchor.constraint(equalTo: container.trailingAnchor).isActive = true
            }
            rowsStack.addArrangedSubview(container)
        }
        refreshKeyCaps()
    }

    // MARK: - Rendering

    private func refreshKeyCaps() {
        let uppercase = shiftState != .off
        for button in keyButtons {
            button.backgroundColor = isSpecial(button.key.action)
                ? KeyboardTheme.specialKeyBackground
                : KeyboardTheme.keyBackground
            button.setTitleColor(KeyboardTheme.keyText, for: .normal)
            button.tintColor = KeyboardTheme.keyText

            switch button.key.action {
            case .character(let c):
                let display = uppercase ? c.uppercased() : c
                button.setTitle(display, for: .normal)
                button.setImage(nil, for: .normal)
                button.currentOutput = display
            case .shift:
                let symbol: String
                switch shiftState {
                case .off: symbol = "shift"
                case .on: symbol = "shift.fill"
                case .capsLock: symbol = "capslock.fill"
                }
                button.setImage(UIImage(systemName: symbol), for: .normal)
                button.setTitle(nil, for: .normal)
            case .backspace:
                button.setImage(UIImage(systemName: "delete.left"), for: .normal)
                button.setTitle(nil, for: .normal)
            case .space:
                button.setTitle(currentLanguage.displayName, for: .normal)
                button.titleLabel?.font = .systemFont(ofSize: 14)
                button.setTitleColor(KeyboardTheme.secondaryText, for: .normal)
            case .returnKey:
                button.setImage(UIImage(systemName: "return"), for: .normal)
                button.setTitle(nil, for: .normal)
            case .switchToSymbols:
                button.setTitle("?123", for: .normal)
                button.titleLabel?.font = .systemFont(ofSize: 16)
            case .switchToLetters:
                button.setTitle("ABC", for: .normal)
                button.titleLabel?.font = .systemFont(ofSize: 16)
            case .switchToSymbolsAlt:
                button.setTitle("=\\<", for: .normal)
                button.titleLabel?.font = .systemFont(ofSize: 16)
            case .globe:
                button.setImage(UIImage(systemName: "globe"), for: .normal)
            }
        }
    }

    private func isSpecial(_ action: KeyAction) -> Bool {
        switch action {
        case .character, .space: return false
        default: return true
        }
    }

    /// Engage shift automatically at sentence starts (letters page only).
    func syncAutoShift() {
        guard page == .letters, currentLanguage != .hindi, shiftState != .capsLock else { return }
        let should = delegate?.keyboardViewShouldAutoCapitalize(self) ?? false
        if should != (shiftState == .on) {
            shiftState = should ? .on : .off
            refreshKeyCaps()
        }
    }

    // MARK: - KeyButtonDelegate

    func keyButtonTapped(_ button: KeyButton) {
        switch button.key.action {
        case .character:
            guard let output = button.currentOutput else { return }
            delegate?.keyboardView(self, didProduceText: output)
            if shiftState == .on {
                shiftState = .off
                refreshKeyCaps()
            }
        case .shift:
            // Double-tap → caps lock.
            if let last = lastShiftTap, Date().timeIntervalSince(last) < 0.3 {
                shiftState = .capsLock
            } else {
                shiftState = (shiftState == .off) ? .on : .off
            }
            lastShiftTap = Date()
            refreshKeyCaps()
        case .backspace:
            delegate?.keyboardViewDidTapBackspace(self)
        case .space:
            delegate?.keyboardViewDidTapSpace(self)
        case .returnKey:
            delegate?.keyboardViewDidTapReturn(self)
        case .switchToSymbols:
            page = .symbols
            rebuild()
        case .switchToLetters:
            page = .letters
            rebuild()
            syncAutoShift()
        case .switchToSymbolsAlt:
            page = .symbolsAlt
            rebuild()
        case .globe:
            delegate?.keyboardViewDidTapGlobe(self)
        }
    }

    func keyButton(_ button: KeyButton, showPreview show: Bool) {
        // Skip the tap bubble while an accent popup is active.
        guard popupOwner == nil || popupOwner === button else { return }
        if show, let output = button.currentOutput {
            popup.present(options: [output], above: button, in: self)
        } else if popupOwner == nil {
            popup.dismiss()
        }
    }

    func keyButton(_ button: KeyButton, longPressChanged recognizer: UILongPressGestureRecognizer) {
        let uppercase = shiftState != .off
        let variants = button.key.variants.map { uppercase ? $0.uppercased() : $0 }
        guard !variants.isEmpty else { return }
        var options = variants
        if let base = button.currentOutput {
            options = [base] + variants
        }

        switch recognizer.state {
        case .began:
            popupOwner = button
            popup.present(options: options, above: button, in: self)
        case .changed:
            popup.updateSelection(forTouchAt: recognizer.location(in: self), in: self)
        case .ended:
            let selected = popup.options.indices.contains(popup.selectedIndex)
                ? popup.options[popup.selectedIndex]
                : options[0]
            popup.dismiss()
            popupOwner = nil
            delegate?.keyboardView(self, didProduceText: selected)
            if shiftState == .on {
                shiftState = .off
                refreshKeyCaps()
            }
        case .cancelled, .failed:
            popup.dismiss()
            popupOwner = nil
        default:
            break
        }
    }

    func keyButtonBeganRepeatingDelete(_ button: KeyButton) {}
    func keyButtonEndedRepeatingDelete(_ button: KeyButton) {}
}
