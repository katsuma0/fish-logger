import CoreLocation
import Foundation
import Observation

/// One shared location manager. Quick logging reads the cached fix so a tap never waits on GPS.
@MainActor
@Observable
final class LocationService: NSObject, CLLocationManagerDelegate {
    static let shared = LocationService()

    private(set) var lastLocation: CLLocation?
    private(set) var authorizationStatus: CLAuthorizationStatus

    private let manager: CLLocationManager
    @ObservationIgnored private var waiters: [CheckedContinuation<CLLocation?, Never>] = []
    @ObservationIgnored private var isTracking = false

    override init() {
        let manager = CLLocationManager()
        self.manager = manager
        self.authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        manager.distanceFilter = 25
    }

    var isAuthorized: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    var isDenied: Bool {
        authorizationStatus == .denied || authorizationStatus == .restricted
    }

    func requestPermission() {
        if authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
    }

    /// Cached fix if it is recent enough. Never waits.
    func recentLocation(maxAge: TimeInterval = 600) -> CLLocation? {
        guard let lastLocation, -lastLocation.timestamp.timeIntervalSinceNow <= maxAge else { return nil }
        return lastLocation
    }

    /// One fix, waiting up to `timeout` seconds. Returns the best known location on timeout,
    /// and nil when permission is missing or nothing is known.
    func currentLocation(maxAge: TimeInterval = 120, timeout: TimeInterval = 10) async -> CLLocation? {
        if let recent = recentLocation(maxAge: maxAge) { return recent }
        requestPermission()
        guard !isDenied else { return lastLocation }
        if authorizationStatus == .notDetermined {
            // Give the permission prompt a moment before asking for a fix.
            try? await Task.sleep(nanoseconds: 300_000_000)
        }
        return await withCheckedContinuation { continuation in
            waiters.append(continuation)
            manager.requestLocation()
            Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                self?.resumeWaiters(with: self?.lastLocation)
            }
        }
    }

    /// Keeps the cached fix fresh during a trip so quick logs get a good position.
    func startTracking() {
        requestPermission()
        guard !isTracking else { return }
        isTracking = true
        manager.startUpdatingLocation()
    }

    func stopTracking() {
        guard isTracking else { return }
        isTracking = false
        manager.stopUpdatingLocation()
    }

    /// Place name like "Lake Simcoe" or "Keswick, ON". Needs a network connection; nil offline.
    func placeName(for location: CLLocation) async -> String? {
        let geocoder = CLGeocoder()
        guard let placemark = try? await geocoder.reverseGeocodeLocation(location).first else { return nil }
        if let water = placemark.inlandWater ?? placemark.ocean { return water }
        if let area = placemark.areasOfInterest?.first { return area }
        let parts = [placemark.locality ?? placemark.subAdministrativeArea, placemark.administrativeArea].compactMap { $0 }
        return parts.isEmpty ? placemark.name : parts.joined(separator: ", ")
    }

    private func resumeWaiters(with location: CLLocation?) {
        let pending = waiters
        waiters.removeAll()
        for waiter in pending { waiter.resume(returning: location) }
    }

    // MARK: CLLocationManagerDelegate

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            self.lastLocation = location
            self.resumeWaiters(with: location)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.resumeWaiters(with: self.lastLocation)
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorizationStatus = status
            if self.isAuthorized, self.isTracking { manager.startUpdatingLocation() }
            if self.isDenied { self.resumeWaiters(with: self.lastLocation) }
        }
    }
}
