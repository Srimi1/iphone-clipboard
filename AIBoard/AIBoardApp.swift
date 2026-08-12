import SwiftUI

@main
struct AIBoardApp: App {
    @StateObject private var router = AppRouter()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(router)
                .onOpenURL { url in
                    router.handle(url: url)
                }
                .onChange(of: scenePhase) { phase in
                    // Capture whatever is on the clipboard whenever the app
                    // becomes active, so history builds up even when the
                    // keyboard isn't open.
                    if phase == .active {
                        ClipboardStore.shared.captureIfChanged()
                    }
                }
        }
    }
}

/// Routes aiboard:// deep links (from the keyboard) to the right tab.
final class AppRouter: ObservableObject {
    enum Tab: Hashable {
        case setup, clipboard, dictation, settings
    }

    @Published var selectedTab: Tab = .setup

    func handle(url: URL) {
        switch url.host ?? url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/")) {
        case "dictate": selectedTab = .dictation
        case "settings": selectedTab = .settings
        case "clipboard": selectedTab = .clipboard
        default: break
        }
    }
}
