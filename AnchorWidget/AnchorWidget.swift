import ActivityKit
import SwiftUI
import WidgetKit

@main
struct AnchorWidgetBundle: WidgetBundle {
    var body: some Widget {
        AnchorLiveActivityWidget()
    }
}

struct AnchorLiveActivityWidget: Widget {
    private func markerColor(_ context: ActivityViewContext<AnchorAttributes>) -> Color {
        switch context.state.markerStyle ?? .black {
        case .black: .black
        case .transparent: .clear
        case .gray: .gray
        }
    }

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AnchorAttributes.self) { context in
            HStack(spacing: 12) {
                Image(systemName: "circle.dotted.circle")
                    .foregroundStyle(.mint)
                VStack(alignment: .leading, spacing: 4) {
                    Text("CURRENT ANCHOR").font(.caption.bold())
                    Text("Experimental placeholder. Open Anchor to stop.")
                        .font(.caption2).foregroundStyle(.gray)
                }
                Spacer(minLength: 0)
            }
            .padding(16)
            .activityBackgroundTint(Color(red: 0.035, green: 0.065, blue: 0.085))
            .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    Text("Current Anchor • Test mode")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Open Anchor to stop the placeholder")
                        .font(.caption2)
                        .foregroundStyle(.gray)
                }
            } compactLeading: {
                Circle().fill(markerColor(context)).frame(width: 6, height: 6)
            } compactTrailing: {
                EmptyView()
            } minimal: {
                Circle().fill(markerColor(context)).frame(width: 5, height: 5)
            }
            .widgetURL(URL(string: "currentanchor://open"))
        }
    }
}
