import ActivityKit
import Foundation

struct AnchorAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        let startedAt: Date
        // Optional to keep activities from the first Anchor build decodable.
        var markerStyle: AnchorMarkerStyle?
        var quietLockScreen: Bool?
    }
    var label: String = "Current Anchor experiment"
}

enum AnchorMarkerStyle: String, Codable, CaseIterable, Identifiable {
    case black
    case transparent
    case empty
    case gray

    var id: String { rawValue }
    var title: String {
        switch self {
        case .black: "Black"
        case .transparent: "Clear"
        case .empty: "Zero"
        case .gray: "Gray"
        }
    }
}
