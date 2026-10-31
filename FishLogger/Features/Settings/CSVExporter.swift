import Foundation

/// Flat CSV of the whole log, one row per catch, for spreadsheets and backups.
enum CSVExporter {
    static let tripColumns = [
        "trip_start", "trip_end", "location", "trip_latitude", "trip_longitude", "water_body", "method",
        "weather", "air_temp_c", "water_temp_c", "pressure_hpa", "pressure_trend", "wind_kmh",
        "wind_dir_deg", "moon_phase"
    ]

    static let catchColumns = [
        "catch_time", "species_id", "species_name", "scientific_name", "count", "size_class", "length_cm",
        "weight_kg", "released", "lure", "depth_m", "catch_latitude", "catch_longitude",
        "catch_pressure_hpa", "notes"
    ]

    static var columns: [String] { tripColumns + catchColumns }

    /// Header row, then one row per catch. A trip with no catches still gets one row so skunked
    /// days show up in the export. Rows run by trip start, then catch time.
    @MainActor
    static func csv(trips: [Trip]) -> String {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.timeZone = TimeZone.current

        var lines: [String] = [row(columns)]
        let sortedTrips = trips.sorted { $0.startDate < $1.startDate }
        for trip in sortedTrips {
            let tripPart = tripFields(trip, dateFormatter: dateFormatter)
            let catches = trip.catches.sorted { $0.timestamp < $1.timestamp }
            if catches.isEmpty {
                let blanks = [String](repeating: "", count: catchColumns.count)
                lines.append(row(tripPart + blanks))
            } else {
                for fishCatch in catches {
                    lines.append(row(tripPart + catchFields(fishCatch, dateFormatter: dateFormatter)))
                }
            }
        }
        return lines.joined(separator: "\r\n")
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

    private static func tripFields(_ trip: Trip, dateFormatter: ISO8601DateFormatter) -> [String] {
        [
            dateFormatter.string(from: trip.startDate),
            trip.endDate.map { dateFormatter.string(from: $0) } ?? "",
            trip.locationName,
            number(trip.latitude, digits: 6),
            number(trip.longitude, digits: 6),
            trip.waterBody.label,
            trip.method.label,
            trip.weather?.label ?? "",
            number(trip.airTempC, digits: 1),
            number(trip.waterTempC, digits: 1),
            number(trip.pressureHPa, digits: 1),
            trip.pressureTrend?.label ?? "",
            number(trip.windSpeedKmh, digits: 1),
            number(trip.windDirectionDeg, digits: 0),
            number(trip.moonPhase, digits: 3)
        ]
    }

    private static func catchFields(_ fishCatch: FishCatch, dateFormatter: ISO8601DateFormatter) -> [String] {
        [
            dateFormatter.string(from: fishCatch.timestamp),
            fishCatch.speciesID,
            fishCatch.speciesName,
            fishCatch.species?.scientificName ?? "",
            String(fishCatch.count),
            fishCatch.sizeClass?.label ?? "",
            number(fishCatch.lengthCm, digits: 1),
            number(fishCatch.weightKg, digits: 3),
            fishCatch.released ? "yes" : "no",
            fishCatch.lure,
            number(fishCatch.depthM, digits: 1),
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
