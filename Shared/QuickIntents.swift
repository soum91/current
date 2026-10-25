import AppIntents
import Foundation
import WidgetKit

struct CurrentActivityIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Show or Hide Current Live Activity"
    static var openAppWhenRun = true
    @MainActor func perform() async throws -> some IntentResult {
        #if !WIDGET_EXTENSION
        await SpeedStore.shared.toggleLiveActivity()
        #endif
        return .result()
    }
}
struct CurrentMonitoringIntent: SetValueIntent, LiveActivityIntent {
    static var title: LocalizedStringResource = "Network Speed Monitoring"
    static var openAppWhenRun = true
    @Parameter(title: "Monitoring") var value: Bool
    @MainActor func perform() async throws -> some IntentResult {
        #if !WIDGET_EXTENSION
        let store = SpeedStore.shared
        UserDefaults.standard.set(value, forKey: "monitoringEnabled")
        if value { store.startMeasuring() } else { store.pauseMeasuring() }
        #endif
        WidgetCenter.shared.reloadAllTimelines()
        ControlCenter.shared.reloadAllControls()
        return .result()
    }
}
