import SwiftUI
import WidgetKit
import AppIntents

@available(iOS 18.0, *)
struct CurrentActivityControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "com.soum91.current.CurrentActivityControl") {
            ControlWidgetButton(action: CurrentActivityIntent()) { Label("Current Live Activity", systemImage: "waveform.path") }
        }.displayName("Current Live Activity").description("Current Live Activity")
    }
}
