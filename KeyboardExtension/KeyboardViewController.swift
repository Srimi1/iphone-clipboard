import UIKit

final class KeyboardViewController: UIInputViewController, KeyboardViewDelegate {

    private let toolbar = ToolbarView()
    private let suggestionBar = SuggestionBarView()
    private let keyboardView = KeyboardView()
    private let clipboardPanel = ClipboardPanelView()

    private let autocorrect = AutocorrectEngine()
    private var clipboardTimer: Timer?
    private var heightConstraint: NSLayoutConstraint?
    private var lastCharacterWasSpace = false

    private var language: KeyboardLanguage { LanguageManager.shared.current }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = KeyboardTheme.background
        buildViewHierarchy()
        keyboardView.configure(language: language)
        toolbar.setLanguageBadge(language)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        keyboardView.configure(language: language)
        keyboardView.syncAutoShift()
        insertPendingTranscriptionIfAny()
        pollClipboard()
        clipboardTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.pollClipboard()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        clipboardTimer?.invalidate()
        clipboardTimer = nil
    }

    override func updateViewConstraints() {
        super.updateViewConstraints()
        let isLandscape = view.bounds.width > 500
        let height: CGFloat = isLandscape ? 220 : 288
        if let constraint = heightConstraint {
            constraint.constant = height
        } else if view.bounds.height > 0 {
            let constraint = view.heightAnchor.constraint(equalToConstant: height)
            constraint.priority = .init(999)
            constraint.isActive = true
            heightConstraint = constraint
        }
    }

    private func buildViewHierarchy() {
        [toolbar, suggestionBar, keyboardView, clipboardPanel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        clipboardPanel.isHidden = true

        NSLayoutConstraint.activate([
            toolbar.topAnchor.constraint(equalTo: view.topAnchor),
            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbar.heightAnchor.constraint(equalToConstant: 40),

            suggestionBar.topAnchor.constraint(equalTo: toolbar.bottomAnchor),
            suggestionBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            suggestionBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            suggestionBar.heightAnchor.constraint(equalToConstant: 32),

            keyboardView.topAnchor.constraint(equalTo: suggestionBar.bottomAnchor),
            keyboardView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            keyboardView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            keyboardView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            clipboardPanel.topAnchor.constraint(equalTo: suggestionBar.bottomAnchor),
            clipboardPanel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            clipboardPanel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            clipboardPanel.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        keyboardView.delegate = self
        wireToolbar()

        suggestionBar.onSuggestionTapped = { [weak self] suggestion in
            guard let self else { return }
            let context = self.textDocumentProxy.documentContextBeforeInput ?? ""
            let word = self.autocorrect.currentWord(in: context) ?? ""
            TextReplacer.replaceCurrentWord(word, with: suggestion, in: self.textDocumentProxy)
            self.refreshSuggestions()
        }

        clipboardPanel.onClipSelected = { [weak self] clip in
            self?.textDocumentProxy.insertText(clip.text)
            self?.setClipboardPanelVisible(false)
        }
    }

    private func wireToolbar() {
        toolbar.onClipboardTapped = { [weak self] in
            guard let self else { return }
            self.setClipboardPanelVisible(self.clipboardPanel.isHidden)
        }
        toolbar.onGlobeTapped = { [weak self] in
            guard let self else { return }
            let next = LanguageManager.shared.cycle()
            self.keyboardView.configure(language: next)
            self.keyboardView.syncAutoShift()
            self.toolbar.setLanguageBadge(next)
            self.refreshSuggestions()
        }
        toolbar.onMicTapped = { [weak self] in
            self?.openContainerApp(path: "dictate")
        }
        toolbar.onFixWithAITapped = { [weak self] in
            self?.fixWithAI()
        }
    }

    // MARK: - KeyboardViewDelegate

    func keyboardView(_ view: KeyboardView, didProduceText text: String) {
        textDocumentProxy.insertText(text)
        lastCharacterWasSpace = false
        refreshSuggestions()
    }

    func keyboardViewDidTapBackspace(_ view: KeyboardView) {
        textDocumentProxy.deleteBackward()
        lastCharacterWasSpace = false
        keyboardView.syncAutoShift()
        refreshSuggestions()
    }

    func keyboardViewDidTapReturn(_ view: KeyboardView) {
        textDocumentProxy.insertText("\n")
        lastCharacterWasSpace = false
        keyboardView.syncAutoShift()
        refreshSuggestions()
    }

    func keyboardViewDidTapSpace(_ view: KeyboardView) {
        let proxy = textDocumentProxy
        // Double-space → ". "
        if lastCharacterWasSpace,
           autocorrect.shouldApplyDoubleSpacePeriod(context: proxy.documentContextBeforeInput) {
            proxy.deleteBackward()
            proxy.insertText(". ")
            lastCharacterWasSpace = false
        } else {
            proxy.insertText(" ")
            lastCharacterWasSpace = true
        }
        keyboardView.syncAutoShift()
        refreshSuggestions()
    }

    func keyboardViewDidTapGlobe(_ view: KeyboardView) {
        toolbar.onGlobeTapped?()
    }

    func keyboardViewShouldAutoCapitalize(_ view: KeyboardView) -> Bool {
        autocorrect.shouldAutoCapitalize(context: textDocumentProxy.documentContextBeforeInput)
    }

    // MARK: - Suggestions

    private func refreshSuggestions() {
        let context = textDocumentProxy.documentContextBeforeInput ?? ""
        let suggestions = autocorrect.suggestions(forCurrentWordIn: context, language: language)
        suggestionBar.update(with: suggestions)
    }

    override func textDidChange(_ textInput: UITextInput?) {
        super.textDidChange(textInput)
        keyboardView.syncAutoShift()
        refreshSuggestions()
    }

    // MARK: - Clipboard

    private func pollClipboard() {
        guard hasFullAccess else {
            if !clipboardPanel.isHidden { clipboardPanel.reload(hasFullAccess: false) }
            return
        }
        let captured = ClipboardStore.shared.captureIfChanged()
        if captured, !clipboardPanel.isHidden {
            clipboardPanel.reload(hasFullAccess: true)
        }
    }

    private func setClipboardPanelVisible(_ visible: Bool) {
        clipboardPanel.isHidden = !visible
        keyboardView.isHidden = visible
        toolbar.setClipboardActive(visible)
        if visible {
            pollClipboard()
            clipboardPanel.reload(hasFullAccess: hasFullAccess)
        }
    }

    // MARK: - Fix with AI

    private func fixWithAI() {
        guard hasFullAccess else {
            toolbar.showStatus("Enable Full Access for AI")
            return
        }
        guard KeychainHelper.loadAPIKey() != nil else {
            toolbar.showStatus("Add API key in the AIBoard app")
            openContainerApp(path: "settings")
            return
        }
        let (before, after) = TextReplacer.visibleText(in: textDocumentProxy)
        let text = (before + after).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            toolbar.showStatus("Nothing to fix")
            return
        }

        toolbar.setAILoading(true)
        Task { [weak self] in
            guard let self else { return }
            do {
                let corrected = try await ClaudeAPI.fixText(before + after, language: self.language)
                await MainActor.run {
                    TextReplacer.replaceVisibleText(with: corrected, in: self.textDocumentProxy) {
                        self.toolbar.setAILoading(false)
                        self.toolbar.showStatus("Fixed ✓")
                        self.refreshSuggestions()
                    }
                }
            } catch {
                await MainActor.run {
                    self.toolbar.setAILoading(false)
                    self.toolbar.showStatus(error.localizedDescription)
                }
            }
        }
    }

    // MARK: - Speech-to-text round trip

    private func insertPendingTranscriptionIfAny() {
        if let text = AppGroup.consumePendingTranscription() {
            textDocumentProxy.insertText(text)
            refreshSuggestions()
        }
    }

    /// Opens the companion app via its URL scheme. `UIApplication.shared.open`
    /// isn't available in extensions, so walk the responder chain.
    private func openContainerApp(path: String) {
        guard let url = URL(string: "aiboard://\(path)") else { return }
        var responder: UIResponder? = self
        let selector = #selector(openURL(_:))
        while let current = responder {
            if current !== self, current.responds(to: selector) {
                current.perform(selector, with: url)
                return
            }
            responder = current.next
        }
    }

    @objc private func openURL(_ url: URL) {
        // Placeholder so the selector exists; the system UIApplication instance
        // up the responder chain performs the actual open.
    }
}
