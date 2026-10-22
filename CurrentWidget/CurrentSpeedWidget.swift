import SwiftUI
import WidgetKit

private enum SpeedWidgetPalette {
    static let down = Color(red: 0.38, green: 0.91, blue: 0.78)
    static let up = Color(red: 1.00, green: 0.66, blue: 0.46)
    static let background = Color(red: 0.035, green: 0.065, blue: 0.085)
}

struct CurrentSpeedEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSpeedSnapshot?

    var isFresh: Bool {
        guard let snapshot else { return false }
        return snapshot.isMeasuring && date.timeIntervalSince(snapshot.updatedAt) < 75
    }
}

struct CurrentSpeedProvider: TimelineProvider {
    func placeholder(in context: Context) -> CurrentSpeedEntry {
        .init(date: .now, snapshot: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (CurrentSpeedEntry) -> Void) {
        completion(.init(date: .now, snapshot: WidgetSpeedStorage.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CurrentSpeedEntry>) -> Void) {
        let now = Date()
        let snapshot = WidgetSpeedStorage.load()
        var entries = [CurrentSpeedEntry(date: now, snapshot: snapshot)]

        // A second entry lets WidgetKit mark the reading stale even when iOS
        // declines to reload our timeline right away.
        if let snapshot, snapshot.isMeasuring {
            let staleAt = snapshot.updatedAt.addingTimeInterval(76)
            if staleAt > now {
                entries.append(.init(date: staleAt, snapshot: snapshot))
            }
        }
        completion(Timeline(entries: entries, policy: .after(now.addingTimeInterval(90))))
    }
}

struct CurrentSpeedWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WidgetSpeedStorage.kind, provider: CurrentSpeedProvider()) { entry in
            CurrentSpeedWidgetView(entry: entry)
        }
        .configurationDisplayName("Current speeds")
        .description("Latest upload and download readings from Current.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

private struct CurrentSpeedWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: CurrentSpeedEntry

    var body: some View {
        VStack(alignment: .leading, spacing: family == .systemSmall ? 9 : 15) {
            HStack(spacing: 6) {
                Image(systemName: "waveform.path")
                    .foregroundStyle(SpeedWidgetPalette.down)
                Text("CURRENT")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(.white)
                Spacer(minLength: 0)
                Circle()
                    .fill(entry.isFresh ? SpeedWidgetPalette.down : Color.gray)
                    .frame(width: 6, height: 6)
            }

            if family == .systemSmall {
                VStack(alignment: .leading, spacing: 9) {
                    rate(label: "DOWN", icon: "arrow.down", down: true, compact: true)
                    rate(label: "UP", icon: "arrow.up", down: false, compact: true)
                }
            } else {
                HStack(alignment: .top, spacing: 20) {
                    rate(label: "DOWNLOAD", icon: "arrow.down.right", down: true, compact: false)
                    Spacer(minLength: 0)
                    rate(label: "UPLOAD", icon: "arrow.up.right", down: false, compact: false)
                }
            }

            Spacer(minLength: 0)
            HStack(spacing: 4) {
                Text(entry.isFresh ? (entry.snapshot?.interfaceLabel ?? "Monitoring") : "Last reading")
                    .lineLimit(1)
                Spacer(minLength: 0)
                if let snapshot = entry.snapshot {
                    Text(snapshot.updatedAt, style: .relative)
                        .lineLimit(1)
                } else {
                    Text("Open app")
                }
            }
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(.white.opacity(0.48))
        }
        .padding(family == .systemSmall ? 13 : 17)
        .containerBackground(for: .widget) {
            LinearGradient(colors: [SpeedWidgetPalette.background, .black], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
        .widgetURL(URL(string: "current://open"))
    }

    private func rate(label: String, icon: String, down: Bool, compact: Bool) -> some View {
        let color = down ? SpeedWidgetPalette.down : SpeedWidgetPalette.up
        let speed = down ? entry.snapshot?.downloadBytesPerSecond : entry.snapshot?.uploadBytesPerSecond
        return VStack(alignment: .leading, spacing: 4) {
            Label(label, systemImage: icon)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(color)
            Text(speed.map { SpeedFormat.rate($0, unit: entry.snapshot?.unit ?? .bytes, compact: compact) } ?? "--")
                .font(.system(size: compact ? 20 : 27, weight: .bold, design: .rounded))
                .foregroundStyle(entry.isFresh ? .white : .white.opacity(0.5))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
