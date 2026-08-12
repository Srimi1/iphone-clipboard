import UIKit

/// Top toolbar: clipboard toggle, Fix-with-AI, mic (dictation via app),
/// globe (language), and a status label for AI feedback.
final class ToolbarView: UIView {
    var onClipboardTapped: (() -> Void)?
    var onFixWithAITapped: (() -> Void)?
    var onMicTapped: (() -> Void)?
    var onGlobeTapped: (() -> Void)?
    var onNextKeyboardTapped: (() -> Void)?

    private let clipboardButton = ToolbarView.makeButton(symbol: "doc.on.clipboard", label: "Clipboard history")
    private let aiButton = ToolbarView.makeButton(symbol: "wand.and.stars", label: "Fix text with AI")
    private let micButton = ToolbarView.makeButton(symbol: "mic", label: "Dictate")
    private let globeButton = ToolbarView.makeButton(symbol: "globe", label: "Change language")
    private let nextKeyboardButton = ToolbarView.makeButton(symbol: "keyboard.chevron.compact.down", label: "Next keyboard")
    private let statusLabel = UILabel()
    private let spinner = UIActivityIndicatorView(style: .medium)

    override init(frame: CGRect) {
        super.init(frame: frame)

        statusLabel.font = .systemFont(ofSize: 13)
        statusLabel.textColor = KeyboardTheme.secondaryText
        statusLabel.textAlignment = .center
        statusLabel.adjustsFontSizeToFitWidth = true
        statusLabel.minimumScaleFactor = 0.7

        let stack = UIStackView(arrangedSubviews: [nextKeyboardButton, clipboardButton, aiButton, statusLabel, spinner, micButton, globeButton])
        stack.axis = .horizontal
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            clipboardButton.widthAnchor.constraint(equalToConstant: 44),
            aiButton.widthAnchor.constraint(equalToConstant: 44),
            micButton.widthAnchor.constraint(equalToConstant: 44),
            globeButton.widthAnchor.constraint(equalToConstant: 44),
            nextKeyboardButton.widthAnchor.constraint(equalToConstant: 44),
        ])
        nextKeyboardButton.isHidden = true
        statusLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

        clipboardButton.addAction(UIAction { [weak self] _ in self?.onClipboardTapped?() }, for: .touchUpInside)
        aiButton.addAction(UIAction { [weak self] _ in self?.onFixWithAITapped?() }, for: .touchUpInside)
        micButton.addAction(UIAction { [weak self] _ in self?.onMicTapped?() }, for: .touchUpInside)
        globeButton.addAction(UIAction { [weak self] _ in self?.onGlobeTapped?() }, for: .touchUpInside)
        nextKeyboardButton.addAction(UIAction { [weak self] _ in self?.onNextKeyboardTapped?() }, for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    private static func makeButton(symbol: String, label: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: symbol), for: .normal)
        button.tintColor = KeyboardTheme.secondaryText
        button.accessibilityLabel = label
        return button
    }

    // MARK: - State

    func setAILoading(_ loading: Bool) {
        aiButton.isEnabled = !loading
        if loading {
            spinner.startAnimating()
        } else {
            spinner.stopAnimating()
        }
    }

    func showStatus(_ message: String, autoClear: Bool = true) {
        statusLabel.text = message
        if autoClear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                if self?.statusLabel.text == message {
                    self?.statusLabel.text = nil
                }
            }
        }
    }

    /// Transient confirmation after a language switch; the spacebar shows the
    /// persistent language name.
    func showLanguageChange(_ language: KeyboardLanguage) {
        showStatus(language.displayName)
    }

    /// Shows the system keyboard-switch key when the host requires one
    /// (`needsInputModeSwitchKey`).
    func setNextKeyboardVisible(_ visible: Bool) {
        nextKeyboardButton.isHidden = !visible
    }

    func setClipboardActive(_ active: Bool) {
        clipboardButton.tintColor = active ? KeyboardTheme.accent : KeyboardTheme.secondaryText
    }
}
