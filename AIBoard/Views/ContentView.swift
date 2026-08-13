import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var router: AppRouter

    var body: some View {
        TabView(selection: $router.selectedTab) {
            OnboardingView()
                .tabItem { Label("Setup", systemImage: "keyboard") }
                .tag(AppRouter.Tab.setup)

            ClipboardHistoryView()
                .tabItem { Label("Clipboard", systemImage: "doc.on.clipboard") }
                .tag(AppRouter.Tab.clipboard)

            DictationView()
                .tabItem { Label("Dictate", systemImage: "mic") }
                .tag(AppRouter.Tab.dictation)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(AppRouter.Tab.settings)
        }
    }
}
