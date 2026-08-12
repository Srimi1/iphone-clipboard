import UIKit

/// Reads and replaces the text around the cursor through the text document proxy.
///
/// Limitation: host apps only expose the text near the cursor (usually the
/// current paragraph), so "Fix with AI" operates on that visible context.
enum TextReplacer {

    /// True while an async replacement is in flight. Callers (the keyboard
    /// controller) must ignore key input while this is set, otherwise typed
    /// characters land in the middle of the delete/insert sequence.
    private(set) static var isReplacing = false

    /// The text the proxy currently exposes: (before cursor, after cursor).
    static func visibleText(in proxy: UITextDocumentProxy) -> (before: String, after: String) {
        (proxy.documentContextBeforeInput ?? "", proxy.documentContextAfterInput ?? "")
    }

    /// Replaces the span captured in `before`/`after` with `newText`.
    ///
    /// The caller passes the context it captured when the operation started
    /// (rather than this function re-reading the proxy) so the deleted span is
    /// exactly the span that was corrected. Because a network round trip can
    /// sit between the capture and this call, the span is re-validated against
    /// the live document first: if the user typed meanwhile, the replacement is
    /// abandoned rather than deleting the wrong number of characters.
    ///
    /// Steps: move the cursor to the end of the visible text, then delete
    /// backwards over everything, then insert the replacement. Deletes are
    /// chunked with short async delays because host apps drop rapid-fire
    /// `deleteBackward` calls.
    ///
    /// `completion` reports whether the replacement was actually applied.
    static func replaceVisibleText(before: String,
                                   after: String,
                                   with newText: String,
                                   in proxy: UITextDocumentProxy,
                                   completion: @escaping (Bool) -> Void) {
        // Only one delete chain may ever be in flight; two interleaved chains
        // scramble the document and clear each other's gate.
        guard !isReplacing else {
            completion(false)
            return
        }
        // The document must still hold the exact span we captured.
        guard (proxy.documentContextBeforeInput ?? "") == before,
              (proxy.documentContextAfterInput ?? "") == after else {
            completion(false)
            return
        }
        isReplacing = true

        // 1. Jump to the end of the visible text. The proxy counts offsets in
        //    UTF-16 code units.
        proxy.adjustTextPosition(byCharacterOffset: after.utf16.count)

        // 2. Give the proxy a moment to sync, then delete in chunks.
        let total = (before + after).count
        deleteBackwardChunked(count: total, proxy: proxy) {
            proxy.insertText(newText)
            isReplacing = false
            completion(true)
        }
    }

    private static func deleteBackwardChunked(count: Int,
                                              proxy: UITextDocumentProxy,
                                              chunkSize: Int = 20,
                                              deleted: Int = 0,
                                              completion: @escaping () -> Void) {
        guard count > 0 else {
            completion()
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            // Stop early once the visible context is exhausted so dropped
            // deletes can't eat text beyond the corrected span. Only after at
            // least one delete has landed: an empty context on the first pass
            // just means the host hasn't synced the cursor move yet, and
            // bailing there would insert the correction without removing the
            // original.
            let remainingContext = proxy.documentContextBeforeInput ?? ""
            if deleted > 0 && remainingContext.isEmpty {
                completion()
                return
            }
            let chunk = min(chunkSize, count)
            for _ in 0..<chunk {
                proxy.deleteBackward()
            }
            deleteBackwardChunked(count: count - chunk, proxy: proxy,
                                  chunkSize: chunkSize, deleted: deleted + chunk,
                                  completion: completion)
        }
    }

    /// Replaces the partial word before the cursor with `suggestion` + a space.
    /// Words are a handful of characters, so a single ≤20-character chunk
    /// suffices; the chunked helper keeps the delete pattern consistent.
    static func replaceCurrentWord(_ word: String,
                                   with suggestion: String,
                                   in proxy: UITextDocumentProxy) {
        guard !isReplacing else { return }
        isReplacing = true
        deleteBackwardChunked(count: word.count, proxy: proxy) {
            proxy.insertText(suggestion + " ")
            isReplacing = false
        }
    }
}
