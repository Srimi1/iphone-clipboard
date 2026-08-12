import UIKit

/// Three tap-to-accept suggestion chips above the keys, Gboard style.
final class SuggestionBarView: UIView {
    var onSuggestionTapped: ((String) -> Void)?

    private let stack = UIStackView()

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
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    func update(with suggestions: [String]) {
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for suggestion in suggestions.prefix(3) {
            let button = UIButton(type: .system)
            button.setTitle(suggestion, for: .normal)
            button.setTitleColor(KeyboardTheme.keyText, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 16)
            button.titleLabel?.lineBreakMode = .byTruncatingTail
            button.addAction(UIAction { [weak self] _ in
                self?.onSuggestionTapped?(suggestion)
            }, for: .touchUpInside)
            stack.addArrangedSubview(button)
        }
    }
}
