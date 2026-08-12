import UIKit

/// Reads and replaces the text around the cursor through the text document proxy.
///
/// Limitation: host apps only expose the text near the cursor (usually the
/// current paragraph), so "Fix with AI" operates on that visible context.
enum TextReplacer {

    /// The text the proxy currently exposes: (before cursor, after cursor).
    static func visibleText(in proxy: UITextDocumentProxy) -> (before: String, after: String) {
        (proxy.documentContextBeforeInput ?? "", proxy.documentContextAfterInput ?? "")
    }

    /// Replaces the visible context with `newText`.
    ///
    /// Steps: move the cursor to the end of the visible text, then delete
    /// backwards over everything, then insert the replacement. Deletes are
    /// chunked with short async delays because host apps drop rapid-fire
    /// `deleteBackward` calls.
    static func replaceVisibleText(with newText: String,
                                   in proxy: UITextDocumentProxy,
                                   completion: @escaping () -> Void) {
        let (before, after) = visibleText(in: proxy)

        // 1. Jump to the end of the visible text.
        proxy.adjustTextPosition(byCharacterOffset: after.count)

        // 2. Give the proxy a moment to sync, then delete in chunks.
        let total = (before + after).count
        deleteBackwardChunked(count: total, proxy: proxy) {
            proxy.insertText(newText)
            completion()
        }
    }

    private static func deleteBackwardChunked(count: Int,
                                              proxy: UITextDocumentProxy,
                                              chunkSize: Int = 20,
                                              completion: @escaping () -> Void) {
        guard count > 0 else {
            completion()
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            let chunk = min(chunkSize, count)
            for _ in 0..<chunk {
                proxy.deleteBackward()
            }
            deleteBackwardChunked(count: count - chunk, proxy: proxy,
                                  chunkSize: chunkSize, completion: completion)
        }
    }

    /// Replaces the partial word before the cursor with `suggestion` + a space.
    static func replaceCurrentWord(_ word: String,
                                   with suggestion: String,
                                   in proxy: UITextDocumentProxy) {
        for _ in 0..<word.count {
            proxy.deleteBackward()
        }
        proxy.insertText(suggestion + " ")
    }
}
