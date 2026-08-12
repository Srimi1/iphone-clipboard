import SwiftUI

struct OnboardingView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Enable the keyboard") {
                    step(1, "Open **Settings → General → Keyboard → Keyboards**")
                    step(2, "Tap **Add New Keyboard…** and choose **AIBoard**")
                    step(3, "Tap **AIBoard** in the list and turn on **Allow Full Access**")
                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("Open AIBoard's app settings (has a Keyboards toggle)", systemImage: "arrow.up.forward.app")
                    }
                }

                Section("Why Full Access?") {
                    Text("Full Access lets the keyboard read your clipboard for the clipboard history and reach the network for AI grammar fixes. Nothing is stored outside your device except the text you explicitly send for correction.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("What you get") {
                    Label("Clipboard history built into the keyboard", systemImage: "doc.on.clipboard")
                    Label("AI grammar & punctuation fixes (✨ key)", systemImage: "wand.and.stars")
                    Label("Speech-to-text via the mic key", systemImage: "mic")
                    Label("English, Español, Français, Deutsch, हिन्दी", systemImage: "globe")
                }

                Section("Next steps") {
                    Text("Add your Claude API key in the **Settings** tab to enable the ✨ Fix-with-AI feature.")
                        .font(.footnote)
                }
            }
            .navigationTitle("AIBoard Setup")
        }
    }

    private func step(_ number: Int, _ text: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.headline)
                .frame(width: 26, height: 26)
                .background(Circle().fill(Color.accentColor.opacity(0.15)))
            Text(text)
        }
    }
}
