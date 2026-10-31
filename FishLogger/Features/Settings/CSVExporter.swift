import Foundation

/// Flat CSV of the whole log, one row per catch, for spreadsheets and backups. Every field the
/// person types or picks is in it, because Settings suggests exporting before Delete everything.
/// Built in two steps: `records(from:)` copies plain values out of the SwiftData models on the
/// thread that owns their context, then `csv(records:)` and `writeFile(records:on:)` turn them
/// into a file on any thread. Settings does both in a background task on its own context.
enum CSVExporter {
    /// One trip as plain values, with its catches oldest first.
    struct TripRecord: Sendable {
        let startDate: Date
        let endDate: Date?
        let locationName: String
        let latitude: Double?
        let longitude: Double?
        let waterBody: String
        let method: String
        let weather: String
        let airTempC: Double?
        let waterTempC: Double?
        let pressureHPa: Double?
        let pressureTrend: String
        let windSpeedKmh: Double?
        let windDirectionDeg: Double?
        let moonPhase: Double?
        let cloudCoverPct: Double?
        let precipitationMm: Double?
        let humidityPct: Double?
        let waterClarity: String
        let waterLevel: String
        let notes: String
        let catches: [CatchRecord]
    }

    /// One catch as plain values.
    struct CatchRecord: Sendable {
        let timestamp: Date
        let speciesID: String
        let speciesName: String
        let scientificName: String
        let count: Int
        let sizeClass: String
        let lengthCm: Double?
        let weightKg: Double?
        let released: Bool
        let lure: String
        let depthM: Double?
        let waterTempC: Double?
        let identifiedBy: String
        let latitude: Double?
        let longitude: Double?
        let pressureHPa: Double?
        let notes: String
    }

    static let tripColumns = [
        "trip_start", "trip_end", "location", "trip_latitude", "trip_longitude", "water_body", "method",
        "weather", "air_temp_c", "water_temp_c", "pressure_hpa", "pressure_trend", "wind_kmh",
        "wind_dir_deg", "moon_phase", "cloud_cover_pct", "precip_mm", "humidity_pct", "water_clarity",
        "water_level", "trip_notes"
    ]

    static let catchColumns = [
        "catch_time", "species_id", "species_name", "scientific_name", "count", "size_class", "length_cm",
        "weight_kg", "released", "lure", "depth_m", "catch_water_temp_c", "identified_by",
        "catch_latitude", "catch_longitude", "catch_pressure_hpa", "notes"
    ]

    static var columns: [String] { tripColumns + catchColumns }

    // MARK: Copying out of the models

    /// Trips by start date, catches by time. Only reads the models, so it can run off the main
    /// thread, but it has to run on the thread that owns the trips' context: the main actor for
    /// the main context, or the background task that made its own `ModelContext`.
    static func records(from trips: [Trip]) -> [TripRecord] {
        trips
            .sorted { $0.startDate < $1.startDate }
            .map { trip -> TripRecord in
                let catches: [CatchRecord] = trip.catches
                    .sorted { $0.timestamp < $1.timestamp }
                    .map { catchRecord($0) }
                return TripRecord(
                    startDate: trip.startDate,
                    endDate: trip.endDate,
                    locationName: trip.locationName,
                    latitude: trip.latitude,
                    longitude: trip.longitude,
                    waterBody: trip.waterBody.label,
                    method: trip.method.label,
                    weather: trip.weather?.label ?? "",
                    airTempC: trip.airTempC,
                    waterTempC: trip.waterTempC,
                    pressureHPa: trip.pressureHPa,
                    pressureTrend: trip.pressureTrend?.label ?? "",
                    windSpeedKmh: trip.windSpeedKmh,
                    windDirectionDeg: trip.windDirectionDeg,
                    moonPhase: trip.moonPhase,
                    cloudCoverPct: trip.cloudCoverPct,
                    precipitationMm: trip.precipitationMm,
                    humidityPct: trip.humidityPct,
                    waterClarity: trip.waterClarity?.label ?? "",
                    waterLevel: trip.waterLevel?.label ?? "",
                    notes: trip.notes,
                    catches: catches
                )
            }
    }

    /// Same thread rule as `records(from:)`.
    private static func catchRecord(_ fishCatch: FishCatch) -> CatchRecord {
        CatchRecord(
            timestamp: fishCatch.timestamp,
            speciesID: fishCatch.speciesID,
            speciesName: fishCatch.speciesName,
            scientificName: fishCatch.species?.scientificName ?? "",
            count: fishCatch.count,
            sizeClass: fishCatch.sizeClass?.label ?? "",
            lengthCm: fishCatch.lengthCm,
            weightKg: fishCatch.weightKg,
            released: fishCatch.released,
            lure: fishCatch.lure,
            depthM: fishCatch.depthM,
            waterTempC: fishCatch.waterTempC,
            identifiedBy: fishCatch.identifiedBy?.label ?? "",
            latitude: fishCatch.latitude,
            longitude: fishCatch.longitude,
            pressureHPa: fishCatch.pressureHPa,
            notes: fishCatch.notes
        )
    }

    // MARK: Building the text

    /// Same output as `csv(records:)`, straight from the models. Fine for small logs and tests;
    /// the Settings export fetches, copies, and builds off the main thread.
    @MainActor
    static func csv(trips: [Trip]) -> String {
        csv(records: records(from: trips))
    }

    /// Header row, then one row per catch. A trip with no catches still gets one row so skunked
    /// days show up in the export. Keeps the order the records are in. Safe on any thread.
    static func csv(records: [TripRecord]) -> String {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.timeZone = TimeZone.current

        var lines: [String] = [row(columns)]
        lines.reserveCapacity(records.count + 1)
        for trip in records {
            let tripPart = tripFields(trip, dateFormatter: dateFormatter)
            if trip.catches.isEmpty {
                let blanks = [String](repeating: "", count: catchColumns.count)
                lines.append(row(tripPart + blanks))
            } else {
                for fishCatch in trip.catches {
                    lines.append(row(tripPart + catchFields(fishCatch, dateFormatter: dateFormatter)))
                }
            }
        }
        return lines.joined(separator: "\r\n")
    }

    /// Builds the CSV and writes it to a temporary file named for the day, ready for the share
    /// sheet. Safe on any thread; call it from a detached task for a big log.
    static func writeFile(records: [TripRecord], on date: Date = .now) throws -> URL {
        let text = csv(records: records)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(exportFileName(on: date))
        try text.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    /// fish-log-2026-10-31.csv. POSIX locale so the digits and calendar never change with region settings.
    static func exportFileName(on date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd"
        return "fish-log-\(formatter.string(from: date)).csv"
    }

    /// RFC 4180: quote a field only when it holds a comma, quote, CR or LF, and double inner quotes.
    /// Checks scalars, not Characters, because "\r\n" is a single Character in Swift.
    static func escape(_ field: String) -> String {
        let needsQuotes = field.unicodeScalars.contains { specialScalars.contains($0) }
        guard needsQuotes else { return field }
        return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    private static let specialScalars: Set<Unicode.Scalar> = [",", "\"", "\r", "\n"]

    private static func row(_ fields: [String]) -> String {
        fields.map { escape($0) }.joined(separator: ",")
    }

    private static func tripFields(_ trip: TripRecord, dateFormatter: ISO8601DateFormatter) -> [String] {
        [
            dateFormatter.string(from: trip.startDate),
            trip.endDate.map { dateFormatter.string(from: $0) } ?? "",
            trip.locationName,
            number(trip.latitude, digits: 6),
            number(trip.longitude, digits: 6),
            trip.waterBody,
            trip.method,
            trip.weather,
            number(trip.airTempC, digits: 1),
            number(trip.waterTempC, digits: 1),
            number(trip.pressureHPa, digits: 1),
            trip.pressureTrend,
            number(trip.windSpeedKmh, digits: 1),
            number(trip.windDirectionDeg, digits: 0),
            number(trip.moonPhase, digits: 3),
            number(trip.cloudCoverPct, digits: 0),
            number(trip.precipitationMm, digits: 1),
            number(trip.humidityPct, digits: 0),
            trip.waterClarity,
            trip.waterLevel,
            trip.notes
        ]
    }

    private static func catchFields(_ fishCatch: CatchRecord, dateFormatter: ISO8601DateFormatter) -> [String] {
        [
            dateFormatter.string(from: fishCatch.timestamp),
            fishCatch.speciesID,
            fishCatch.speciesName,
            fishCatch.scientificName,
            String(fishCatch.count),
            fishCatch.sizeClass,
            number(fishCatch.lengthCm, digits: 1),
            number(fishCatch.weightKg, digits: 3),
            fishCatch.released ? "yes" : "no",
            fishCatch.lure,
            number(fishCatch.depthM, digits: 1),
            number(fishCatch.waterTempC, digits: 1),
            fishCatch.identifiedBy,
            number(fishCatch.latitude, digits: 6),
            number(fishCatch.longitude, digits: 6),
            number(fishCatch.pressureHPa, digits: 1),
            fishCatch.notes
        ]
    }

    /// String(format:) ignores the user's locale, so decimals always use "." and never a comma,
    /// which would break the column split.
    private static func number(_ value: Double?, digits: Int) -> String {
        guard let value, value.isFinite else { return "" }
        return String(format: "%.\(digits)f", value)
    }
}
