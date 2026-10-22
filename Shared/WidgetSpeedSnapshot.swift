import Foundation

struct WidgetSpeedSnapshot: Codable {
    let downloadBytesPerSecond: Double
    let uploadBytesPerSecond: Double
    let interfaceLabel: String
    let unit: SpeedUnit
    let updatedAt: Date
    let isMeasuring: Bool
}

enum WidgetSpeedStorage {
    static let kind = "CurrentSpeedWidget"
    static let appGroup = "group.com.soum91.current"
    private static let key = "current.latestSpeedSnapshot"

    @discardableResult
    static func save(_ snapshot: WidgetSpeedSnapshot) -> Bool {
        guard let defaults = UserDefaults(suiteName: appGroup),
              let data = try? JSONEncoder().encode(snapshot) else { return false }
        defaults.set(data, forKey: key)
        return true
    }

    static func load() -> WidgetSpeedSnapshot? {
        guard let defaults = UserDefaults(suiteName: appGroup),
              let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(WidgetSpeedSnapshot.self, from: data)
    }
}
