import SwiftUI

struct ClipboardHistoryView: View {
    @State private var clips: [Clip] = []

    var body: some View {
        NavigationStack {
            Group {
                if clips.isEmpty {
                    ContentUnavailableCompat()
                } else {
                    List {
                        ForEach(clips) { clip in
                            Button {
                                UIPasteboard.general.string = clip.text
                                ClipboardStore.shared.captureIfChanged(userInitiated: true)
                                reload()
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(clip.text)
                                        .lineLimit(3)
                                        .foregroundStyle(.primary)
                                    HStack {
                                        if clip.pinned {
                                            Label("Pinned", systemImage: "pin.fill")
                                                .font(.caption2)
                                        }
                                        Text(clip.date, style: .relative)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    ClipboardStore.shared.delete(clip)
                                    reload()
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                Button {
                                    ClipboardStore.shared.togglePin(clip)
                                    reload()
                                } label: {
                                    Label(clip.pinned ? "Unpin" : "Pin", systemImage: "pin")
                                }
                                .tint(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Clipboard")
            .toolbar {
                if !clips.isEmpty {
                    Button("Clear Unpinned") {
                        ClipboardStore.shared.deleteAllUnpinned()
                        reload()
                    }
                }
            }
            .onAppear {
                ClipboardStore.shared.captureIfChanged(userInitiated: true)
                reload()
            }
        }
    }

    private func reload() {
        ClipboardStore.shared.load()
        clips = ClipboardStore.shared.sortedClips
    }
}

/// Simple empty state (avoids the iOS 17-only ContentUnavailableView).
private struct ContentUnavailableCompat: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text("No clips yet")
                .font(.headline)
            Text("Copy some text anywhere — it will show up here and in the keyboard's clipboard panel.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}
