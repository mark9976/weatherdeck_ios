import CoreLocation
import Foundation

/// Wraps CLLocationManager for one-shot location requests and geocoding search.
@Observable
final class LocationService: NSObject, CLLocationManagerDelegate {
    var lastLocation: CLLocationCoordinate2D?
    var authStatus: CLAuthorizationStatus = .notDetermined
    var error: String?

    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocationCoordinate2D?, Never>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        authStatus = manager.authorizationStatus
    }

    /// Request permission + get a single location fix.
    func requestLocation() async -> CLLocationCoordinate2D? {
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
            // Wait a beat for the permission dialog
            try? await Task.sleep(for: .seconds(1))
        }
        guard manager.authorizationStatus == .authorizedWhenInUse ||
              manager.authorizationStatus == .authorizedAlways else {
            error = "Location permission denied."
            return nil
        }
        return await withCheckedContinuation { cont in
            continuation = cont
            manager.requestLocation()
        }
    }

    // MARK: - CLLocationManagerDelegate

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let coord = locations.first?.coordinate
        Task { @MainActor in
            self.lastLocation = coord
            self.continuation?.resume(returning: coord)
            self.continuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.error = error.localizedDescription
            self.continuation?.resume(returning: nil)
            self.continuation = nil
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authStatus = manager.authorizationStatus
        }
    }

    // MARK: - Geocoding (search by name/ZIP)

    struct GeoResult: Identifiable {
        let id = UUID()
        let name: String
        let lat: Double
        let lon: Double
    }

    func search(_ query: String) async -> [GeoResult] {
        let geocoder = CLGeocoder()
        do {
            let placemarks = try await geocoder.geocodeAddressString(query)
            return placemarks.compactMap { pm in
                guard let loc = pm.location else { return nil }
                let parts = [pm.locality, pm.administrativeArea, pm.country].compactMap { $0 }
                let name = parts.isEmpty ? "\(loc.coordinate.latitude), \(loc.coordinate.longitude)" : parts.joined(separator: ", ")
                return GeoResult(name: name, lat: loc.coordinate.latitude, lon: loc.coordinate.longitude)
            }
        } catch {
            return []
        }
    }
}
