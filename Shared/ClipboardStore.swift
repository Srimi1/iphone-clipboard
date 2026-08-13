import Foundation
import UIKit

struct Clip: Codable, Identifiable, Equatable {
    let id: UUID
    var text: String
    var date: Date
    var pinned: Bool

    init(text: String, date: Date = Date(), pinned: Bool = false) {
        self.id = UUID()
        self.text = text
        self.date = date
        self.pinned = pinned
    }
}

/// Clipboard history persisted as JSON in the App Group container so both the
/// companion app and the keyboard extension see the same list.
final class ClipboardStore {
    static let shared = ClipboardStore()

    private let maxUnpinned = 50
    private let fileURL: URL? = AppGroup.containerURL?.appendingPathComponent("clips.json")
    private let coordinator = NSFileCoordinator()

    private(set) var clips: [Clip] = []

    private init() {
        load()
    }

    // MARK: - Capture

    /// Reads the general pasteboard only when its changeCount differs from the
    /// last one we stored — reading `.string` triggers the iOS paste prompt, so
    /// we avoid doing it unless something actually changed.
    ///
    /// The change count is committed only once there is nothing left to capture
    /// for that pasteboard generation. If the user denies the paste prompt, a
    /// `userInitiated` call leaves it uncommitted so the clip can still be
    /// captured later; polled calls always commit so the timer can't loop the
    /// system alert.
    ///
    /// Returns true if a new clip was captured.
    @discardableResult
    func captureIfChanged(userInitiated: Bool = false) -> Bool {
        let pasteboard = UIPasteboard.general
        let count = pasteboard.changeCount
        let lastCount = AppGroup.defaults.integer(forKey: AppGroup.Key.lastPasteboardChangeCount)
        guard count != lastCount else { return false }

        func commit() {
            AppGroup.defaults.set(count, forKey: AppGroup.Key.lastPasteboardChangeCount)
        }

        // hasStrings does not raise the paste prompt; .string does.
        guard pasteboard.hasStrings else {
            commit()
            return false
        }
        guard let text = pasteboard.string else {
            if !userInitiated { commit() }
            return false
        }
        commit()
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }
        add(text)
        return true
    }

    // MARK: - Mutations

    /// Runs `body` as a complete read-modify-write inside ONE coordinated
    /// write. The app and the keyboard extension are separate processes over a
    /// single file, so reloading and saving as two transactions would leave a
    /// window where each writes a different snapshot and the later write
    /// discards the other's clips. Re-reading inside the lock closes it.
    private func mutate(_ body: @escaping () -> Void) {
        guard let url = fileURL else {
            body()
            return
        }
        coordinator.coordinate(writingItemAt: url, options: [], error: nil) { actualURL in
            if let data = try? Data(contentsOf: actualURL),
               let decoded = try? JSONDecoder().decode([Clip].self, from: data) {
                self.clips = decoded
            }
            body()
            if let data = try? JSONEncoder().encode(self.clips) {
                try? data.write(to: actualURL, options: .atomic)
            }
        }
    }

    func add(_ text: String) {
        mutate {
            if let existing = clips.firstIndex(where: { $0.text == text }) {
                // Move a refreshed duplicate to the front so storage order
                // stays newest-first and trim() keeps the most recent clips.
                var clip = clips.remove(at: existing)
                clip.date = Date()
                clips.insert(clip, at: 0)
            } else {
                clips.insert(Clip(text: text), at: 0)
            }
            trim()
        }
    }

    func togglePin(_ clip: Clip) {
        mutate {
            guard let index = clips.firstIndex(where: { $0.id == clip.id }) else { return }
            clips[index].pinned.toggle()
        }
    }

    func delete(_ clip: Clip) {
        mutate {
            clips.removeAll { $0.id == clip.id }
        }
    }

    func deleteAllUnpinned() {
        mutate {
            clips.removeAll { !$0.pinned }
        }
    }

    /// Pinned clips first, then by recency.
    var sortedClips: [Clip] {
        clips.sorted {
            if $0.pinned != $1.pinned { return $0.pinned }
            return $0.date > $1.date
        }
    }

    // MARK: - Persistence

    func load() {
        guard let url = fileURL else { return }
        // NSFileCoordinator serializes access across the app and the keyboard
        // extension, which run as separate processes on the same file.
        coordinator.coordinate(readingItemAt: url, options: [], error: nil) { actualURL in
            guard let data = try? Data(contentsOf: actualURL),
                  let decoded = try? JSONDecoder().decode([Clip].self, from: data) else { return }
            self.clips = decoded
        }
    }

    /// Caps unpinned clips. Storage order is newest-first, so this keeps the
    /// most recent ones. Called from inside `mutate`.
    private func trim() {
        var unpinnedCount = 0
        clips = clips.filter { clip in
            if clip.pinned { return true }
            unpinnedCount += 1
            return unpinnedCount <= maxUnpinned
        }
    }
}
