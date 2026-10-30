import CoreLocation
import Foundation
import SwiftData

/// One outing. A trip with no `endDate` is the active one, and quick logging attaches to it.
@Model
final class Trip {
    var id: UUID = UUID()
    var startDate: Date = Date()
    var endDate: Date?
    var locationName: String = ""
    var latitude: Double?
    var longitude: Double?
    var waterBodyRaw: String = WaterBodyType.lake.rawValue
    var methodRaw: String = FishingMethod.shore.rawValue

    // Conditions. Everything is optional because offline days and forgetful days both happen.
    var weatherRaw: String?
    var airTempC: Double?
    var waterTempC: Double?
    /// Sea-level pressure, so it lines up with weather reports.
    var pressureHPa: Double?
    var pressureTrendRaw: String?
    var windSpeedKmh: Double?
    var windDirectionDeg: Double?
    var cloudCoverPct: Double?
    var humidityPct: Double?
    var precipitationMm: Double?
    var waterClarityRaw: String?
    var waterLevelRaw: String?
    /// 0 is new moon, 0.5 is full, back to 1.
    var moonPhase: Double?
    var sunrise: Date?
    var sunset: Date?
    /// Set when weather came from the network, so a later refresh knows it can overwrite.
    var weatherFetchedAt: Date?
    var notes: String = ""

    @Relationship(deleteRule: .cascade, inverse: \FishCatch.trip)
    var catches: [FishCatch] = []

    init(
        startDate: Date = .now,
        locationName: String = "",
        latitude: Double? = nil,
        longitude: Double? = nil,
        waterBody: WaterBodyType = .lake,
        method: FishingMethod = .shore
    ) {
        self.id = UUID()
        self.startDate = startDate
        self.locationName = locationName
        self.latitude = latitude
        self.longitude = longitude
        self.waterBodyRaw = waterBody.rawValue
        self.methodRaw = method.rawValue
    }
}

extension Trip {
    var isActive: Bool { endDate == nil }

    var displayName: String {
        let trimmed = locationName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Unnamed spot" : trimmed
    }

    var dayStart: Date { Calendar.current.startOfDay(for: startDate) }

    /// Elapsed time. Uses now for an active trip.
    var duration: TimeInterval { max(0, (endDate ?? .now).timeIntervalSince(startDate)) }

    /// Total fish, counting multi-fish entries.
    var totalFish: Int { catches.reduce(0) { $0 + $1.count } }

    /// Newest first.
    var sortedCatches: [FishCatch] { catches.sorted { $0.timestamp > $1.timestamp } }

    var coordinate: CLLocationCoordinate2D? {
        guard let latitude, let longitude else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var waterBody: WaterBodyType {
        get { WaterBodyType(rawValue: waterBodyRaw) ?? .other }
        set { waterBodyRaw = newValue.rawValue }
    }

    var method: FishingMethod {
        get { FishingMethod(rawValue: methodRaw) ?? .shore }
        set { methodRaw = newValue.rawValue }
    }

    var weather: WeatherCondition? {
        get { weatherRaw.flatMap(WeatherCondition.init(rawValue:)) }
        set { weatherRaw = newValue?.rawValue }
    }

    var pressureTrend: PressureTrend? {
        get { pressureTrendRaw.flatMap(PressureTrend.init(rawValue:)) }
        set { pressureTrendRaw = newValue?.rawValue }
    }

    var waterClarity: WaterClarity? {
        get { waterClarityRaw.flatMap(WaterClarity.init(rawValue:)) }
        set { waterClarityRaw = newValue?.rawValue }
    }

    var waterLevel: WaterLevel? {
        get { waterLevelRaw.flatMap(WaterLevel.init(rawValue:)) }
        set { waterLevelRaw = newValue?.rawValue }
    }

    /// Species ids caught on this trip with fish counts, most caught first.
    var speciesTally: [(speciesID: String, count: Int)] {
        var tally: [String: Int] = [:]
        for fishCatch in catches { tally[fishCatch.speciesID, default: 0] += fishCatch.count }
        return tally
            .map { (speciesID: $0.key, count: $0.value) }
            .sorted { $0.count == $1.count ? $0.speciesID < $1.speciesID : $0.count > $1.count }
    }
}
