import CoreLocation
import Foundation

/// Optional background location session. Coordinates are never retained or sent.
/// iOS decides whether the session can keep Current executing in the background.
@MainActor
final class BackgroundLocationController: NSObject, CLLocationManagerDelegate {
    var onStatusChange: ((Bool, String) -> Void)?
    var onLocationUpdate: (() -> Void)?

    private let manager = CLLocationManager()
    private var requested = false
    private var authorizationRequested = false
    private(set) var isRunning = false

    override init() {
        super.init()
        manager.delegate = self
        manager.activityType = .other
        manager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        manager.distanceFilter = kCLDistanceFilterNone
        manager.pausesLocationUpdatesAutomatically = false
        // Apple applies this only to Always-authorized sessions. Other iOS
        // privacy indicators, including Control Center, remain system-owned.
        manager.showsBackgroundLocationIndicator = false
    }

    func enable() {
        requested = true
        switch manager.authorizationStatus {
        case .authorizedAlways:
            startSession()
        case .notDetermined, .authorizedWhenInUse:
            if !authorizationRequested {
                authorizationRequested = true
                manager.requestAlwaysAuthorization()
            }
            onStatusChange?(false, "Waiting for Always location permission")
        case .denied, .restricted:
            onStatusChange?(false, "Location denied. Change access to Always in iOS Settings")
        @unknown default:
            onStatusChange?(false, "Location authorization unavailable")
        }
    }

    func disable() {
        requested = false
        if isRunning {
            manager.stopUpdatingLocation()
            manager.allowsBackgroundLocationUpdates = false
        }
        isRunning = false
        onStatusChange?(false, "Off")
    }

    private func startSession() {
        guard requested, !isRunning else { return }
        // Requires UIBackgroundModes/location in the app's Info.plist.
        manager.allowsBackgroundLocationUpdates = true
        manager.startUpdatingLocation()
        isRunning = true
        onStatusChange?(true, "Always authorized · background session active")
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard requested else { return }
        switch manager.authorizationStatus {
        case .authorizedAlways:
            startSession()
        case .authorizedWhenInUse:
            onStatusChange?(false, "When In Use granted. Change to Always in iOS Settings")
        case .denied, .restricted:
            disable()
            onStatusChange?(false, "Location denied. Change access to Always in iOS Settings")
        case .notDetermined:
            onStatusChange?(false, "Waiting for Always location permission")
        @unknown default:
            onStatusChange?(false, "Location authorization unavailable")
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Use the delivery event only. Never read, store, or transmit coordinates.
        onLocationUpdate?()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        guard (error as? CLError)?.code == .denied else { return }
        disable()
        onStatusChange?(false, "Location permission revoked. Background monitoring stopped")
    }
}
