import CoreMotion
import Foundation
import Observation

/// Reads the iPhone's built-in barometer. Works offline, which is the point.
@MainActor
@Observable
final class BarometerService {
    static let shared = BarometerService()

    /// Raw pressure at the phone, in hPa. Not sea-level adjusted.
    private(set) var stationPressureHPa: Double?
    private(set) var lastReadingDate: Date?

    @ObservationIgnored private let altimeter = CMAltimeter()
    @ObservationIgnored private var isRunning = false
    @ObservationIgnored private var waiters: [CheckedContinuation<Double?, Never>] = []

    var isAvailable: Bool { CMAltimeter.isRelativeAltitudeAvailable() }

    func start() {
        guard isAvailable, !isRunning else { return }
        isRunning = true
        altimeter.startRelativeAltitudeUpdates(to: .main) { [weak self] data, _ in
            guard let data else { return }
            // CoreMotion reports kilopascals.
            let hPa = data.pressure.doubleValue * 10
            MainActor.assumeIsolated {
                self?.record(hPa)
            }
        }
    }

    func stop() {
        guard isRunning else { return }
        isRunning = false
        altimeter.stopRelativeAltitudeUpdates()
    }

    /// One reading, starting the sensor if needed. Nil on devices without a barometer or on timeout.
    func readOnce(timeout: TimeInterval = 4) async -> Double? {
        guard isAvailable else { return nil }
        if let lastReadingDate, -lastReadingDate.timeIntervalSinceNow < 60, let stationPressureHPa {
            return stationPressureHPa
        }
        let wasRunning = isRunning
        start()
        let value: Double? = await withCheckedContinuation { continuation in
            waiters.append(continuation)
            Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                self?.resumeWaiters(with: self?.stationPressureHPa)
            }
        }
        if !wasRunning { stop() }
        return value
    }

    /// Latest reading converted to sea level, or nil if there is no recent reading.
    func seaLevelPressureHPa(altitudeM: Double?, airTempC: Double? = nil, maxAge: TimeInterval = 900) -> Double? {
        guard let stationPressureHPa, let lastReadingDate, -lastReadingDate.timeIntervalSinceNow <= maxAge else { return nil }
        return Self.seaLevel(stationHPa: stationPressureHPa, altitudeM: altitudeM ?? 0, airTempC: airTempC ?? 15)
    }

    /// Standard barometric reduction to sea level, the same correction weather stations apply.
    nonisolated static func seaLevel(stationHPa: Double, altitudeM: Double, airTempC: Double = 15) -> Double {
        let lapse = 0.0065 * altitudeM
        return stationHPa * pow(1 - lapse / (airTempC + lapse + 273.15), -5.257)
    }

    private func record(_ hPa: Double) {
        stationPressureHPa = hPa
        lastReadingDate = .now
        resumeWaiters(with: hPa)
    }

    private func resumeWaiters(with value: Double?) {
        let pending = waiters
        waiters.removeAll()
        for waiter in pending { waiter.resume(returning: value) }
    }
}
