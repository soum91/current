import ActivityKit
import Foundation

struct AnchorAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        let startedAt: Date
    }
    var label: String = "Current Anchor experiment"
}
