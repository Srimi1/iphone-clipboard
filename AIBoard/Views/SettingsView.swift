import SwiftUI

struct SettingsView: View {
    @State private var apiKey: String = KeychainHelper.loadAPIKey() ?? ""
    @State private var testState: TestState = .idle
    @State private var enabledLanguages = Set(LanguageManager.shared.enabled)

    private enum TestState {
        case idle, testing, success, failure
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("sk-ant-…", text: $apiKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .disabled(testState == .testing)
                    HStack {
                        Button("Save") {
                            KeychainHelper.saveAPIKey(apiKey)
                            testState = .idle
                        }
                        .disabled(testState == .testing)
                        Spacer()
                        Button("Test") {
                            testKey()
                        }
                        .disabled(apiKey.isEmpty || testState == .testing)
                        testIndicator
                    }
                    // Without this, the Form row is a single hit target and
                    // tapping either button fires both.
                    .buttonStyle(.borderless)
                } header: {
                    Text("Claude API Key")
                } footer: {
                    Text("Used by the keyboard's ✨ Fix-with-AI feature. Get a key at console.anthropic.com. Stored on this device only.")
                }

                Section {
                    ForEach(KeyboardLanguage.allCases) { lang in
                        Toggle(lang.displayName, isOn: binding(for: lang))
                    }
                } header: {
                    Text("Keyboard Languages")
                } footer: {
                    Text("The globe key on the keyboard cycles through the enabled languages.")
                }
            }
            .navigationTitle("Settings")
        }
    }

    @ViewBuilder
    private var testIndicator: some View {
        switch testState {
        case .idle:
            EmptyView()
        case .testing:
            ProgressView()
        case .success:
            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
        case .failure:
            Image(systemName: "xmark.circle.fill").foregroundStyle(.red)
        }
    }

    private func binding(for lang: KeyboardLanguage) -> Binding<Bool> {
        Binding {
            enabledLanguages.contains(lang)
        } set: { isOn in
            if isOn {
                enabledLanguages.insert(lang)
            } else if enabledLanguages.count > 1 {
                enabledLanguages.remove(lang)
            }
            LanguageManager.shared.enabled = KeyboardLanguage.allCases.filter(enabledLanguages.contains)
        }
    }

    private func testKey() {
        testState = .testing
        let key = apiKey
        Task {
            let ok = await ClaudeAPI.testKey(key)
            await MainActor.run {
                testState = ok ? .success : .failure
                if ok { KeychainHelper.saveAPIKey(key) }
            }
        }
    }
}
