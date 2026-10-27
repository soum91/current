import SwiftUI
import AppIntents

@main
struct CurrentApp: App {
    @StateObject private var store = SpeedStore.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
                .onAppear { store.startMeasuring() }
                .onOpenURL { _ in store.startMeasuring() }
                .onChange(of: scenePhase) { phase in
                    store.scenePhaseChanged(phase)
                }
        }
    }
}


/// Use Apple's visible Shortcut control while native Control Widgets fail to draw.
struct CurrentShortcuts: AppShortcutsProvider {
    static var shortcutTileColor: ShortcutTileColor = .blue

    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: CurrentActivityIntent(), phrases: [
            "Toggle network speed in \(.applicationName)",
        ], shortTitle: "Speed Island", systemImageName: "network")
    }
}
