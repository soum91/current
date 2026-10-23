import ActivityKit
import Foundation

struct SpeedActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var downloadBytesPerSecond: Double
        var uploadBytesPerSecond: Double
        var unit: SpeedUnit
        var interfaceLabel: String
        var updatedAt: Date
        var isMeasuring: Bool
        // Optional for compatibility with Live Activities started by older builds.
        var islandLayout: IslandLayout?
        var leadingTemplate: String?
        var trailingTemplate: String?
        var minimalTopTemplate: String?
        var minimalBottomTemplate: String?
        var customTextSize: Double?
    }

    var label: String = "Network speed"
}

enum SpeedUnit: String, Codable, CaseIterable, Identifiable {
    case bytes
    case bits

    var id: String { rawValue }
    var title: String { self == .bytes ? "Bytes/s" : "Bits/s" }
}

enum IslandLayout: String, Codable, CaseIterable, Identifiable {
    case classic
    case slim
    case custom

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

enum IslandTemplate {
    static let leading = "↓{down}"
    static let trailing = "↑{up}"
    static let top = "↓{down}"
    static let bottom = "↑{up}"

    static func limited(_ template: String) -> String {
        String(template.prefix(40))
    }

    static func render(_ template: String, download: Double, upload: Double,
                       unit: SpeedUnit, interface: String = "") -> String {
        var value = limited(template)
        let replacements = [
            "{down}": SpeedFormat.minimalRate(download, unit: unit),
            "{up}": SpeedFormat.minimalRate(upload, unit: unit),
            "{down.full}": SpeedFormat.rate(download, unit: unit, compact: true),
            "{up.full}": SpeedFormat.rate(upload, unit: unit, compact: true),
            "{interface}": interface
        ]
        for (token, replacement) in replacements {
            value = value.replacingOccurrences(of: token, with: replacement)
        }
        return String(value.replacingOccurrences(of: "\n", with: " ").prefix(48))
    }
}

enum SpeedFormat {
    static func rate(_ bytesPerSecond: Double, unit: SpeedUnit, compact: Bool = false) -> String {
        let amount = max(0, bytesPerSecond) * (unit == .bits ? 8 : 1)
        let suffixes = unit == .bits ? ["bps", "Kbps", "Mbps", "Gbps"] : ["B/s", "KB/s", "MB/s", "GB/s"]
        let compactSuffixes = unit == .bits ? ["b", "K", "M", "G"] : ["B", "K", "M", "G"]
        var value = amount
        var level = 0
        while value >= 1_000 && level < 3 {
            value /= 1_000
            level += 1
        }
        let numeric: String
        if value >= 100 { numeric = String(format: "%.0f", value) }
        else if value >= 10 { numeric = String(format: "%.1f", value) }
        else { numeric = String(format: "%.1f", value) }
        return numeric + (compact ? compactSuffixes[level] : " " + suffixes[level])
    }

    /// Four characters or fewer so the secondary Dynamic Island can show a rate.
    static func minimalRate(_ bytesPerSecond: Double, unit: SpeedUnit) -> String {
        var value = max(0, bytesPerSecond) * (unit == .bits ? 8 : 1)
        var level = 0
        while value >= 1_000 && level < 3 {
            value /= 1_000
            level += 1
        }
        if value >= 999.5 && level < 3 {
            value /= 1_000
            level += 1
        }
        let amount: String
        if value >= 10 || level == 0 {
            amount = String(format: "%.0f", value)
        } else {
            amount = String(format: "%.1f", value)
        }
        let suffix = level == 0 ? (unit == .bits ? "b" : "B") : ["", "K", "M", "G"][level]
        return amount + suffix
    }

    static func amount(_ bytes: UInt64) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(clamping: bytes), countStyle: .decimal)
    }
}
