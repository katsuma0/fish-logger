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
    /// Callers waiting on a fix, by id, so each one is answered exactly once: by the next fix, a
    /// failure, or its own timeout, whichever comes first.
    @ObservationIgnored private var waiters: [UUID: CheckedContinuation<CLLocation?, Never>] = [:]
    @ObservationIgnored private var timeouts: [UUID: Task<Void, Never>] = [:]
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

    /// One fix, waiting up to `timeout` seconds. On timeout or failure it falls back to the cached
    /// fix only while that is under 10 minutes old. An older one is likely from another spot, and
    /// would put the wrong lake, sun times, and weather on a trip, so the answer is nil instead.
    func currentLocation(maxAge: TimeInterval = 120, timeout: TimeInterval = 10) async -> CLLocation? {
        if let recent = recentLocation(maxAge: maxAge) { return recent }
        requestPermission()
        guard !isDenied else { return recentLocation(maxAge: Self.fallbackMaxAge) }
        if authorizationStatus == .notDetermined {
            // Give the permission prompt a moment before asking for a fix.
            try? await Task.sleep(nanoseconds: 300_000_000)
        }
        let id = UUID()
        let location: CLLocation? = await withCheckedContinuation { continuation in
            waiters[id] = continuation
            manager.requestLocation()
            timeouts[id] = Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                guard !Task.isCancelled else { return }
                self?.resumeWaiter(id)
            }
        }
        // Timeout and failure answer with the cached fix, which can be hours old.
        guard let location, -location.timestamp.timeIntervalSinceNow <= Self.fallbackMaxAge else { return nil }
        return location
    }

    /// Oldest cached fix that may stand in when a new one does not come. Same as `recentLocation`'s
    /// default, which is what starting a trip already accepts.
    private static let fallbackMaxAge: TimeInterval = 600

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

    /// Fishing region for where the phone is now. Needs a fix and a network connection; nil otherwise.
    /// When permission has not been asked yet, it waits for the answer first, so the time spent
    /// reading the prompt does not use up the time allowed for a fix.
    func currentRegion() async -> FishingRegion? {
        if authorizationStatus == .notDetermined {
            requestPermission()
            await waitForPermissionAnswer()
        }
        guard isAuthorized, !Task.isCancelled else { return nil }
        // Long enough for a first fix from a cold start, which can take a while indoors.
        guard let location = await currentLocation(timeout: 15) else { return nil }
        guard let placemark = try? await CLGeocoder().reverseGeocodeLocation(location).first,
              let area = placemark.administrativeArea
        else { return nil }
        return FishingRegion.from(administrativeArea: area)
    }

    /// Returns once the person answers the location prompt, after a minute, or when cancelled.
    /// The status is set on the main actor by the delegate, so a short poll sees it.
    private func waitForPermissionAnswer() async {
        let deadline = Date.now.addingTimeInterval(60)
        while authorizationStatus == .notDetermined, Date.now < deadline, !Task.isCancelled {
            try? await Task.sleep(nanoseconds: 250_000_000)
        }
    }

    /// Answers every waiter and cancels their timeouts.
    private func resumeWaiters(with location: CLLocation?) {
        let pending = Array(waiters.values)
        waiters.removeAll()
        for timeout in timeouts.values { timeout.cancel() }
        timeouts.removeAll()
        for waiter in pending { waiter.resume(returning: location) }
    }

    /// Timeout for one waiter. Does nothing if a fix already answered it.
    private func resumeWaiter(_ id: UUID) {
        timeouts[id] = nil
        guard let waiter = waiters.removeValue(forKey: id) else { return }
        waiter.resume(returning: lastLocation)
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
