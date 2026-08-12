import Foundation
import AVFoundation
import Speech

/// Live speech-to-text using SFSpeechRecognizer + AVAudioEngine.
/// The final transcript is written to the App Group so the keyboard can
/// insert it the next time it appears.
@MainActor
final class SpeechRecognizer: ObservableObject {
    @Published var transcript: String = ""
    @Published var isRecording = false
    @Published var errorMessage: String?
    @Published var isAuthorized = false

    private var audioEngine: AVAudioEngine?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                guard status == .authorized else {
                    self?.isAuthorized = false
                    self?.errorMessage = "Speech recognition permission denied. Enable it in Settings."
                    return
                }
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    DispatchQueue.main.async {
                        self?.isAuthorized = granted
                        if !granted {
                            self?.errorMessage = "Microphone permission denied. Enable it in Settings."
                        }
                    }
                }
            }
        }
    }

    func start(language: KeyboardLanguage) {
        guard !isRecording else { return }
        errorMessage = nil
        transcript = ""

        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: language.localeIdentifier)),
              recognizer.isAvailable else {
            errorMessage = "Speech recognition isn't available for \(language.displayName) right now."
            return
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            let engine = AVAudioEngine()
            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true

            let inputNode = engine.inputNode
            let format = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
                request.append(buffer)
            }

            engine.prepare()
            try engine.start()

            self.audioEngine = engine
            self.request = request
            self.isRecording = true

            task = recognizer.recognitionTask(with: request) { [weak self] result, error in
                DispatchQueue.main.async {
                    guard let self else { return }
                    if let result {
                        self.transcript = result.bestTranscription.formattedString
                    }
                    if error != nil || (result?.isFinal ?? false) {
                        self.stopEngineOnly()
                    }
                }
            }
        } catch {
            errorMessage = "Could not start recording: \(error.localizedDescription)"
            stopEngineOnly()
        }
    }

    /// Stops recording; the current transcript stays on screen.
    func stop() {
        request?.endAudio()
        stopEngineOnly()
    }

    private func stopEngineOnly() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine = nil
        // finish() lets the task deliver the final result for audio already
        // accepted; cancel() would drop it.
        task?.finish()
        task = nil
        request = nil
        isRecording = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    /// Hands the transcript to the keyboard via the App Group.
    func sendToKeyboard() {
        let text = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        AppGroup.setPendingTranscription(text)
    }
}
