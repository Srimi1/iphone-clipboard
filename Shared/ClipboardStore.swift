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
    private let queue = DispatchQueue(label: "com.yourteam.aiboard.clipboardstore")

    private(set) var clips: [Clip] = []

    private init() {
        load()
    }

    // MARK: - Capture

    /// Reads the general pasteboard only when its changeCount differs from the
    /// last one we stored — reading `.string` triggers the iOS paste banner, so
    /// we avoid doing it unless something actually changed.
    /// Returns true if a new clip was captured.
    @discardableResult
    func captureIfChanged() -> Bool {
        let pasteboard = UIPasteboard.general
        let lastCount = AppGroup.defaults.integer(forKey: AppGroup.Key.lastPasteboardChangeCount)
        guard pasteboard.changeCount != lastCount else { return false }
        AppGroup.defaults.set(pasteboard.changeCount, forKey: AppGroup.Key.lastPasteboardChangeCount)

        guard pasteboard.hasStrings, let text = pasteboard.string,
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }
        add(text)
        return true
    }

    // MARK: - Mutations

    func add(_ text: String) {
        load() // pick up writes from the other process
        if let existing = clips.firstIndex(where: { $0.text == text }) {
            clips[existing].date = Date()
        } else {
            clips.insert(Clip(text: text), at: 0)
        }
        trim()
        save()
    }

    func togglePin(_ clip: Clip) {
        guard let index = clips.firstIndex(where: { $0.id == clip.id }) else { return }
        clips[index].pinned.toggle()
        save()
    }

    func delete(_ clip: Clip) {
        clips.removeAll { $0.id == clip.id }
        save()
    }

    func deleteAllUnpinned() {
        clips.removeAll { !$0.pinned }
        save()
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
        guard let url = fileURL, let data = try? Data(contentsOf: url) else { return }
        if let decoded = try? JSONDecoder().decode([Clip].self, from: data) {
            clips = decoded
        }
    }

    private func trim() {
        var unpinnedCount = 0
        clips = clips.filter { clip in
            if clip.pinned { return true }
            unpinnedCount += 1
            return unpinnedCount <= maxUnpinned
        }
    }

    private func save() {
        guard let url = fileURL else { return }
        let snapshot = clips
        queue.async {
            if let data = try? JSONEncoder().encode(snapshot) {
                try? data.write(to: url, options: .atomic)
            }
        }
    }
}
