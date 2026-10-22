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
    }

    var label: String = "Network speed"
}

enum SpeedUnit: String, Codable, CaseIterable, Identifiable {
    case bytes
    case bits

    var id: String { rawValue }
    var title: String { self == .bytes ? "Bytes/s" : "Bits/s" }
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

    static func amount(_ bytes: UInt64) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(clamping: bytes), countStyle: .decimal)
    }
}
