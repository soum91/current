import ActivityKit
import SwiftUI
import WidgetKit

private enum IslandColor {
    static let down = Color(red: 0.38, green: 0.91, blue: 0.78)
    static let up = Color(red: 1.00, green: 0.66, blue: 0.46)
}

@main
struct CurrentWidgetBundle: WidgetBundle {
    var body: some Widget {
        CurrentLiveActivity()
        CurrentSpeedWidget()
    }
}

struct CurrentLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SpeedActivityAttributes.self) { context in
            lockScreen(context)
                .activityBackgroundTint(Color(red: 0.04, green: 0.07, blue: 0.09))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    HStack(spacing: 28) {
                        expandedSpeed(context, down: true)
                        expandedSpeed(context, down: false)
                    }
                    .padding(.top, 6)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(isFresh(context) ? IslandColor.down : .gray)
                            .frame(width: 6, height: 6)
                        Text(isFresh(context) ? context.state.interfaceLabel : "Paused · Open Current to resume")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.65))
                    }
                    .padding(.bottom, 8)
                }
            } compactLeading: {
                EmptyView()
            } compactTrailing: {
                VStack(spacing: 0) {
                    Text("↓\(SpeedFormat.minimalRate(context.state.downloadBytesPerSecond, unit: context.state.unit))")
                        .foregroundStyle(isFresh(context) ? IslandColor.down : .gray)
                    Text("↑\(SpeedFormat.minimalRate(context.state.uploadBytesPerSecond, unit: context.state.unit))")
                        .foregroundStyle(isFresh(context) ? IslandColor.up : .gray)
                }
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.65)
                .frame(width: 32, height: 30)
                .accessibilityLabel("Download \(SpeedFormat.rate(context.state.downloadBytesPerSecond, unit: context.state.unit)), upload \(SpeedFormat.rate(context.state.uploadBytesPerSecond, unit: context.state.unit))")
            } minimal: {
                VStack(spacing: 0) {
                    Text("↓\(SpeedFormat.minimalRate(context.state.downloadBytesPerSecond, unit: context.state.unit))")
                        .foregroundStyle(isFresh(context) ? IslandColor.down : .gray)
                    Text("↑\(SpeedFormat.minimalRate(context.state.uploadBytesPerSecond, unit: context.state.unit))")
                        .foregroundStyle(isFresh(context) ? IslandColor.up : .gray)
                }
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.65)
                .frame(width: 32, height: 30)
                .accessibilityLabel("Download \(SpeedFormat.rate(context.state.downloadBytesPerSecond, unit: context.state.unit)), upload \(SpeedFormat.rate(context.state.uploadBytesPerSecond, unit: context.state.unit))")
            }
            .widgetURL(URL(string: "current://open"))
        }
    }

    private func isFresh(_ context: ActivityViewContext<SpeedActivityAttributes>) -> Bool {
        context.state.isMeasuring && !context.isStale
    }

    private func expandedSpeed(_ context: ActivityViewContext<SpeedActivityAttributes>, down: Bool) -> some View {
        let color = down ? IslandColor.down : IslandColor.up
        let value = down ? context.state.downloadBytesPerSecond : context.state.uploadBytesPerSecond
        return VStack(alignment: .leading, spacing: 5) {
            Label(down ? "Download" : "Upload", systemImage: down ? "arrow.down.right" : "arrow.up.right")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(color)
            Text(SpeedFormat.rate(value, unit: context.state.unit))
                .font(.system(size: 19, weight: .bold, design: .rounded))
                .foregroundStyle(isFresh(context) ? .white : .gray)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
    }

    private func lockScreen(_ context: ActivityViewContext<SpeedActivityAttributes>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "waveform.path")
                        .foregroundStyle(IslandColor.down)
                    Text("CURRENT")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .tracking(1.4)
                }
                Spacer()
                Text(isFresh(context) ? context.state.interfaceLabel : "Paused")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }
            HStack(spacing: 20) {
                expandedSpeed(context, down: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                expandedSpeed(context, down: false)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
    }
}
