import SwiftUI
import WidgetKit
import AppIntents
struct CurrentMonitoringProvider: ControlValueProvider {
    var previewValue: Bool { false }
    func currentValue() async throws -> Bool { WidgetSpeedStorage.load()?.isMeasuring ?? false }
}
struct CurrentMonitoringControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "com.soum91.current.monitoring", provider: CurrentMonitoringProvider()) { on in
            ControlWidgetToggle("Network speeds", isOn: on, action: CurrentMonitoringIntent()) { Label($0 ? "Monitoring" : "Paused", systemImage: "waveform.path") }
        }.displayName("Speed monitoring").description("Start or stop Current. Opens the app to start its sampling session.")
    }
}
struct CurrentLockWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "CurrentLockSpeeds", provider: CurrentSpeedProvider()) { entry in
            CurrentLockView(entry: entry).containerBackground(for: .widget) { Color.clear }
        }.configurationDisplayName("Network speeds").description("Latest network sample. Use the Live Activity for ongoing updates.")
            .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}
struct CurrentLockView: View {
    @Environment(\.widgetFamily) var family
    var entry: CurrentSpeedEntry
    func rate(_ down: Bool) -> String {
        guard let s = entry.snapshot else { return "--" }
        return SpeedFormat.rate(down ? s.downloadBytesPerSecond : s.uploadBytesPerSecond, unit: s.unit, compact: true)
    }
    var body: some View {
        Group {
            if family == .accessoryInline { Text("↓ \(rate(true)) ↑ \(rate(false))") }
            else if family == .accessoryCircular {
                ZStack { AccessoryWidgetBackground(); VStack(spacing: 1) {
                    Image(systemName: "arrow.down"); Text(rate(true)).font(.caption2).minimumScaleFactor(0.5)
                } }
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    Text("↓ \(rate(true))").font(.headline)
                    Text("↑ \(rate(false))").font(.caption)
                    Text(entry.isFresh ? (entry.snapshot?.interfaceLabel ?? "Current") : "Last sample · Open Current").font(.caption2)
                }
            }
        }.widgetURL(URL(string: "current://open"))
    }
}
