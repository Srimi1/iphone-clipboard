import UIKit

/// The Android-style bubble shown above a key: either a single-character tap
/// preview, or a row of accent variants selectable by sliding the finger.
final class KeyPopupView: UIView {
    private var labels: [UILabel] = []
    private(set) var selectedIndex: Int = 0
    private(set) var options: [String] = []

    private let preferredItemWidth: CGFloat = 38
    private let minimumItemWidth: CGFloat = 24
    private let itemHeight: CGFloat = 46
    /// Actual per-item width for the current presentation, shrunk when the
    /// option list would otherwise overflow the container.
    private var itemWidth: CGFloat = 38

    init() {
        super.init(frame: .zero)
        backgroundColor = KeyboardTheme.popupBackground
        layer.cornerRadius = 8
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.25
        layer.shadowRadius = 4
        layer.shadowOffset = CGSize(width: 0, height: 2)
        isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    /// Positions the popup above `key` inside `container` showing `options`.
    func present(options: [String], above key: UIView, in container: UIView) {
        self.options = options
        selectedIndex = 0
        labels.forEach { $0.removeFromSuperview() }
        labels = options.map { text in
            let label = UILabel()
            label.text = text
            label.font = .systemFont(ofSize: 22)
            label.textAlignment = .center
            label.textColor = KeyboardTheme.keyText
            label.layer.cornerRadius = 6
            label.clipsToBounds = true
            addSubview(label)
            return label
        }

        // Fit the bubble inside the container: shrink items down to a minimum
        // tappable width before allowing any overflow.
        let available = container.bounds.width - 16
        itemWidth = max(minimumItemWidth,
                        min(preferredItemWidth, (available - 8) / CGFloat(max(1, options.count))))
        let width = min(itemWidth * CGFloat(options.count) + 8, available)
        let keyFrame = key.convert(key.bounds, to: container)
        var x = keyFrame.midX - width / 2
        x = max(4, min(x, max(4, container.bounds.width - width - 4)))
        frame = CGRect(x: x, y: keyFrame.minY - itemHeight - 8, width: width, height: itemHeight)

        for (i, label) in labels.enumerated() {
            label.frame = CGRect(x: 4 + CGFloat(i) * itemWidth, y: 4,
                                 width: itemWidth, height: itemHeight - 8)
        }
        highlight(index: 0)
        container.addSubview(self)
    }

    /// Updates the highlighted variant based on the finger's x in container coordinates.
    func updateSelection(forTouchAt point: CGPoint, in container: UIView) {
        let local = container.convert(point, to: self)
        let index = Int((local.x - 4) / itemWidth)
        highlight(index: max(0, min(options.count - 1, index)))
    }

    private func highlight(index: Int) {
        selectedIndex = index
        for (i, label) in labels.enumerated() {
            label.backgroundColor = (i == index) ? KeyboardTheme.accent : .clear
            label.textColor = (i == index) ? .white : KeyboardTheme.keyText
        }
    }

    func dismiss() {
        removeFromSuperview()
    }
}
