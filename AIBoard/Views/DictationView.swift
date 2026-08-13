import SwiftUI

struct DictationView: View {
    @StateObject private var recognizer = SpeechRecognizer()
    @State private var language = LanguageManager.shared.current
    @State private var sent = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Picker("Language", selection: $language) {
                    ForEach(LanguageManager.shared.enabled) { lang in
                        Text(lang.displayName).tag(lang)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .disabled(recognizer.isRecording)

                ScrollView {
                    Text(recognizer.transcript.isEmpty
                         ? "Tap the mic and start speaking…"
                         : recognizer.transcript)
                        .font(.title3)
                        .foregroundStyle(recognizer.transcript.isEmpty ? .secondary : .primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
                .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)

                if let error = recognizer.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Button {
                    if recognizer.isRecording {
                        recognizer.stop()
                    } else {
                        sent = false
                        recognizer.start(language: language)
                    }
                } label: {
                    Image(systemName: recognizer.isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 34))
                        .frame(width: 84, height: 84)
                        .background(Circle().fill(recognizer.isRecording ? Color.red : Color.accentColor))
                        .foregroundStyle(.white)
                }
                .disabled(!recognizer.isAuthorized)

                Button {
                    recognizer.sendToKeyboard()
                    sent = true
                } label: {
                    Label(sent ? "Ready — switch back to your app" : "Use in keyboard",
                          systemImage: sent ? "checkmark.circle.fill" : "keyboard")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
                .disabled(recognizer.transcript.isEmpty || recognizer.isRecording)

                if sent {
                    Text("Return to the app you were typing in — the text will be inserted when the keyboard opens.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer()
            }
            .padding(.top)
            .navigationTitle("Dictation")
            .onAppear {
                recognizer.requestPermissions()
                language = LanguageManager.shared.current
            }
        }
    }
}
