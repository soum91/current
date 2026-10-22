import CoreLocation
import Foundation

/// Experimental, opt-in background execution through a real Core Location session.
/// Current neither saves nor transmits any CLLocation data. iOS may still suspend us.
@MainActor
final class BackgroundLocationController: NSObject, CLLocationManagerDelegate {
    var onStatusChange: ((Bool, String?) -> Void)?

    private let manager = CLLocationManager()
    private var requested = false
    private(set) var isRunning = false

    override init() {
        super.init()
        manager.delegate = self
        // A coarse fix is significantly cheaper than GPS navigation accuracy.
        manager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        manager.distanceFilter = kCLDistanceFilterNone
        manager.pausesLocationUpdatesAutomatically = false
        manager.showsBackgroundLocationIndicator = true
    }

    func enable() {
        requested = true
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            startSession()
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            onStatusChange?(false, "Location access is off. Allow location while using Current in iOS Settings to try experimental background monitoring.")
        @unknown default:
            onStatusChange?(false, "Location authorization is unavailable.")
        }
    }

    func disable() {
        requested = false
        if isRunning {
            manager.stopUpdatingLocation()
            manager.allowsBackgroundLocationUpdates = false
        }
        isRunning = false
        onStatusChange?(false, nil)
    }

    private func startSession() {
        guard !isRunning else { return }
        // UIBackgroundModes=location must be present, otherwise iOS terminates the app.
        manager.allowsBackgroundLocationUpdates = true
        manager.startUpdatingLocation()
        isRunning = true
        onStatusChange?(true, nil)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if requested {
            enable()
        } else if isRunning {
            disable()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Intentionally discard coordinates. Receiving updates keeps the location
        // session active; location itself is never used for network measurements.
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        guard (error as? CLError)?.code == .denied else { return }
        disable()
        onStatusChange?(false, "Location permission was revoked. Background monitoring stopped.")
    }
}
