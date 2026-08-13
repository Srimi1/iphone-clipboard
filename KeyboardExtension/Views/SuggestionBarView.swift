import UIKit

/// Three tap-to-accept suggestion chips above the keys, Gboard style.
final class SuggestionBarView: UIView {
    var onSuggestionTapped: ((String) -> Void)?

    private let stack = UIStackView()
    // Three persistent buttons — update() runs on every keystroke, and the
    // extension's memory budget is tight, so avoid churning UIButtons.
    private var buttons: [UIButton] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 1
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
        ])

        for _ in 0..<3 {
            let button = UIButton(type: .system)
            button.setTitleColor(KeyboardTheme.keyText, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 16)
            button.titleLabel?.lineBreakMode = .byTruncatingTail
            button.isHidden = true
            button.addAction(UIAction { [weak self, weak button] _ in
                guard let title = button?.title(for: .normal) else { return }
                self?.onSuggestionTapped?(title)
            }, for: .touchUpInside)
            buttons.append(button)
            stack.addArrangedSubview(button)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    func update(with suggestions: [String]) {
        for (index, button) in buttons.enumerated() {
            if index < suggestions.count {
                button.setTitle(suggestions[index], for: .normal)
                button.isHidden = false
            } else {
                button.setTitle(nil, for: .normal)
                button.isHidden = true
            }
        }
    }
}
