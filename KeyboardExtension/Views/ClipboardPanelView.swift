import UIKit

/// Clipboard history panel that overlays the key area. Tap a clip to insert
/// it; swipe a row for pin/delete.
final class ClipboardPanelView: UIView, UITableViewDataSource, UITableViewDelegate {
    var onClipSelected: ((Clip) -> Void)?

    private let tableView = UITableView()
    private let emptyLabel = UILabel()
    private var clips: [Clip] = []
    private var hasFullAccess = true

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = KeyboardTheme.background

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "clip")
        tableView.backgroundColor = .clear
        tableView.separatorColor = KeyboardTheme.keyBackground
        tableView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(tableView)

        emptyLabel.text = "No clips yet.\nCopy something and it will appear here."
        emptyLabel.numberOfLines = 0
        emptyLabel.textAlignment = .center
        emptyLabel.font = .systemFont(ofSize: 14)
        emptyLabel.textColor = KeyboardTheme.secondaryText
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(emptyLabel)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: topAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            emptyLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            emptyLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 20),
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    func reload(hasFullAccess: Bool) {
        self.hasFullAccess = hasFullAccess
        ClipboardStore.shared.load()
        clips = ClipboardStore.shared.sortedClips
        if !hasFullAccess {
            emptyLabel.text = "Full Access is off.\nEnable it in Settings → General → Keyboard →\nKeyboards → AIBoard → Allow Full Access."
        } else {
            emptyLabel.text = "No clips yet.\nCopy something and it will appear here."
        }
        emptyLabel.isHidden = !clips.isEmpty && hasFullAccess
        // Without Full Access the message replaces the list entirely —
        // otherwise stale persisted clips render behind the label.
        tableView.isHidden = !hasFullAccess
        tableView.reloadData()
    }

    // MARK: - Table view

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        clips.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "clip", for: indexPath)
        let clip = clips[indexPath.row]
        var config = cell.defaultContentConfiguration()
        config.text = clip.text
        config.textProperties.numberOfLines = 2
        config.textProperties.font = .systemFont(ofSize: 15)
        config.textProperties.color = KeyboardTheme.keyText
        if clip.pinned {
            config.secondaryText = "📌 Pinned"
            config.secondaryTextProperties.font = .systemFont(ofSize: 11)
            config.secondaryTextProperties.color = KeyboardTheme.secondaryText
        }
        cell.contentConfiguration = config
        cell.backgroundColor = .clear
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        onClipSelected?(clips[indexPath.row])
    }

    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let clip = clips[indexPath.row]
        let delete = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, done in
            ClipboardStore.shared.delete(clip)
            self?.reload(hasFullAccess: self?.hasFullAccess ?? true)
            done(true)
        }
        let pin = UIContextualAction(style: .normal, title: clip.pinned ? "Unpin" : "Pin") { [weak self] _, _, done in
            ClipboardStore.shared.togglePin(clip)
            self?.reload(hasFullAccess: self?.hasFullAccess ?? true)
            done(true)
        }
        pin.backgroundColor = KeyboardTheme.accent
        let configuration = UISwipeActionsConfiguration(actions: [delete, pin])
        // A full swipe would delete with no confirmation and no undo.
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }
}
