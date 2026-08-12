import UIKit

protocol KeyButtonDelegate: AnyObject {
    func keyButtonTapped(_ button: KeyButton)
    func keyButton(_ button: KeyButton, showPreview show: Bool)
    func keyButton(_ button: KeyButton, longPressChanged recognizer: UILongPressGestureRecognizer)
    func keyButtonBeganRepeatingDelete(_ button: KeyButton)
    func keyButtonEndedRepeatingDelete(_ button: KeyButton)
}

/// One key. Flat, rounded-rect, Android-ish. Handles the tap preview bubble,
/// backspace auto-repeat, and long-press for accent variants.
final class KeyButton: UIButton {
    let key: Key
    weak var delegate: KeyButtonDelegate?

    private var deleteTimer: Timer?
    private var isRepeating = false

    /// The text this key inserts given the current shift state (nil for control keys).
    var currentOutput: String?

    init(key: Key) {
        self.key = key
        super.init(frame: .zero)

        layer.cornerRadius = 6
        titleLabel?.font = .systemFont(ofSize: 22)
        translatesAutoresizingMaskIntoConstraints = false

        addTarget(self, action: #selector(touchDown), for: .touchDown)
        addTarget(self, action: #selector(touchUpInside), for: .touchUpInside)
        addTarget(self, action: #selector(touchEnded), for: [.touchUpOutside, .touchCancel, .touchDragExit])

        if !key.variants.isEmpty {
            let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
            longPress.minimumPressDuration = 0.35
            addGestureRecognizer(longPress)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    private var isCharacterKey: Bool {
        if case .character = key.action { return true }
        return false
    }

    // MARK: - Touch handling

    @objc private func touchDown() {
        if isCharacterKey {
            delegate?.keyButton(self, showPreview: true)
        }
        if key.action == .backspace {
            startRepeatingDelete()
        }
    }

    @objc private func touchUpInside() {
        delegate?.keyButton(self, showPreview: false)
        if key.action == .backspace {
            stopRepeatingDelete()
            if !isRepeating { delegate?.keyButtonTapped(self) }
            isRepeating = false
            return
        }
        delegate?.keyButtonTapped(self)
    }

    @objc private func touchEnded() {
        delegate?.keyButton(self, showPreview: false)
        if key.action == .backspace {
            stopRepeatingDelete()
            isRepeating = false
        }
    }

    // MARK: - Backspace auto-repeat

    private func startRepeatingDelete() {
        deleteTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            guard let self else { return }
            self.isRepeating = true
            self.delegate?.keyButtonBeganRepeatingDelete(self)
            self.deleteTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                guard let self else { return }
                self.delegate?.keyButtonTapped(self)
            }
        }
    }

    private func stopRepeatingDelete() {
        deleteTimer?.invalidate()
        deleteTimer = nil
        delegate?.keyButtonEndedRepeatingDelete(self)
    }

    // MARK: - Long press (accents)

    @objc private func handleLongPress(_ recognizer: UILongPressGestureRecognizer) {
        delegate?.keyButton(self, longPressChanged: recognizer)
    }
}
