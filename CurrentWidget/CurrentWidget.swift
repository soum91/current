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
        CurrentLockWidget()
        CurrentMonitoringControl()
        CurrentActivityControl()

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
                compactLeading(context)
            } compactTrailing: {
                compactTrailing(context)
            } minimal: {
                minimalContent(context)
            }
            .widgetURL(URL(string: "current://open"))
        }
    }

    private func isFresh(_ context: ActivityViewContext<SpeedActivityAttributes>) -> Bool {
        context.state.isMeasuring && !context.isStale
    }

    @ViewBuilder
    private func compactLeading(_ context: ActivityViewContext<SpeedActivityAttributes>) -> some View {
        switch context.state.islandLayout ?? .classic {
        case .classic: classicCompactSpeed(context, down: true)
        case .slim: EmptyView()
        case .custom: customCompactText(context, down: true)
        }
    }

    @ViewBuilder
    private func compactTrailing(_ context: ActivityViewContext<SpeedActivityAttributes>) -> some View {
        switch context.state.islandLayout ?? .classic {
        case .classic: classicCompactSpeed(context, down: false)
        case .slim: standardMinimalContent(context)
        case .custom: customCompactText(context, down: false)
        }
    }

    @ViewBuilder
    private func minimalContent(_ context: ActivityViewContext<SpeedActivityAttributes>) -> some View {
        if context.state.islandLayout == .custom {
            customMinimalContent(context)
        } else {
            // Identical to the working detached layout from build 12.
            standardMinimalContent(context)
        }
    }

    private func classicCompactSpeed(_ context: ActivityViewContext<SpeedActivityAttributes>, down: Bool) -> some View {
        let color = down ? IslandColor.down : IslandColor.up
        let value = down ? context.state.downloadBytesPerSecond : context.state.uploadBytesPerSecond
        return HStack(spacing: 3) {
            Image(systemName: down ? "arrow.down" : "arrow.up")
                .font(.system(size: 10, weight: .bold))
            Text(SpeedFormat.rate(value, unit: context.state.unit, compact: true))
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .foregroundStyle(isFresh(context) ? color : .gray)
    }

    private func standardMinimalContent(_ context: ActivityViewContext<SpeedActivityAttributes>) -> some View {
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

    private func customCompactText(_ context: ActivityViewContext<SpeedActivityAttributes>, down: Bool) -> some View {
        let template = down ? (context.state.leadingTemplate ?? IslandTemplate.leading)
                            : (context.state.trailingTemplate ?? IslandTemplate.trailing)
        let label = IslandTemplate.render(template,
            download: context.state.downloadBytesPerSecond,
            upload: context.state.uploadBytesPerSecond,
            unit: context.state.unit, interface: context.state.interfaceLabel)
        let color = down ? IslandColor.down : IslandColor.up
        return Text(label)
            .font(.system(size: context.state.customTextSize ?? 10, weight: .bold, design: .rounded))
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .foregroundStyle(isFresh(context) ? color : .gray)
    }

    private func customMinimalContent(_ context: ActivityViewContext<SpeedActivityAttributes>) -> some View {
        let top = IslandTemplate.render(context.state.minimalTopTemplate ?? IslandTemplate.top,
            download: context.state.downloadBytesPerSecond, upload: context.state.uploadBytesPerSecond,
            unit: context.state.unit, interface: context.state.interfaceLabel)
        let bottom = IslandTemplate.render(context.state.minimalBottomTemplate ?? IslandTemplate.bottom,
            download: context.state.downloadBytesPerSecond, upload: context.state.uploadBytesPerSecond,
            unit: context.state.unit, interface: context.state.interfaceLabel)
        return VStack(spacing: 0) {
            Text(top).foregroundStyle(isFresh(context) ? IslandColor.down : .gray)
            Text(bottom).foregroundStyle(isFresh(context) ? IslandColor.up : .gray)
        }
        .font(.system(size: min(context.state.customTextSize ?? 10, 11), weight: .bold, design: .rounded))
        .monospacedDigit()
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .frame(width: 32, height: 30)
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
