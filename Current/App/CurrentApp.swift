import SwiftUI

@main
struct CurrentApp: App {
    @StateObject private var store = SpeedStore()
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
