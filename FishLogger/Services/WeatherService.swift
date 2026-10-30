import Foundation

struct WeatherSnapshot: Equatable {
    var time: Date
    var condition: WeatherCondition?
    var airTempC: Double?
    /// Sea-level pressure.
    var pressureHPa: Double?
    var pressureTrend: PressureTrend?
    var windSpeedKmh: Double?
    var windGustKmh: Double?
    var windDirectionDeg: Double?
    var cloudCoverPct: Double?
    var humidityPct: Double?
    var precipitationMm: Double?
}

enum WeatherError: LocalizedError {
    case tooOld
    case badResponse
    case noData

    var errorDescription: String? {
        switch self {
        case .tooOld: "Weather history only goes back 92 days."
        case .badResponse: "The weather service sent something unexpected."
        case .noData: "No weather data for that time and place."
        }
    }
}

/// Hourly weather from Open-Meteo. Free, no API key, and it keeps 92 days of history,
/// so a trip logged offline can be filled in later.
enum WeatherService {
    static let maxPastDays = 92

    static func url(latitude: Double, longitude: Double, pastDays: Int) -> URL {
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(format: "%.4f", latitude)),
            URLQueryItem(name: "longitude", value: String(format: "%.4f", longitude)),
            URLQueryItem(name: "hourly", value: "temperature_2m,relative_humidity_2m,precipitation,weather_code,cloud_cover,pressure_msl,wind_speed_10m,wind_direction_10m,wind_gusts_10m"),
            URLQueryItem(name: "past_days", value: String(pastDays)),
            URLQueryItem(name: "forecast_days", value: "1"),
            URLQueryItem(name: "wind_speed_unit", value: "kmh"),
            URLQueryItem(name: "timeformat", value: "unixtime"),
            URLQueryItem(name: "timezone", value: "auto")
        ]
        return components.url!
    }

    static func fetch(
        latitude: Double,
        longitude: Double,
        at date: Date = .now,
        session: URLSession = .shared
    ) async throws -> WeatherSnapshot {
        let daysAgo = Int(ceil(max(0, -date.timeIntervalSinceNow) / 86_400))
        guard daysAgo <= maxPastDays else { throw WeatherError.tooOld }
        let request = URLRequest(
            url: url(latitude: latitude, longitude: longitude, pastDays: min(maxPastDays, daysAgo + 1)),
            timeoutInterval: 15
        )
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw WeatherError.badResponse
        }
        return try parse(data, at: date)
    }

    /// Picks the hour closest to `date`. The trend compares against three hours earlier.
    static func parse(_ data: Data, at date: Date) throws -> WeatherSnapshot {
        let decoded: Response
        do { decoded = try JSONDecoder().decode(Response.self, from: data) } catch { throw WeatherError.badResponse }
        let hourly = decoded.hourly
        guard !hourly.time.isEmpty else { throw WeatherError.noData }

        let target = date.timeIntervalSince1970
        var bestIndex = 0
        var bestDistance = Double.greatestFiniteMagnitude
        for (index, time) in hourly.time.enumerated() {
            let distance = abs(time - target)
            if distance < bestDistance {
                bestDistance = distance
                bestIndex = index
            }
        }
        // More than three hours off means the data does not cover this time.
        guard bestDistance <= 3 * 3600 else { throw WeatherError.noData }

        func value(_ series: [Double?]?, _ index: Int) -> Double? {
            guard let series, index >= 0, index < series.count else { return nil }
            return series[index]
        }

        let pressure = value(hourly.pressure_msl, bestIndex)
        var trend: PressureTrend?
        if let pressure, let earlier = value(hourly.pressure_msl, bestIndex - 3) {
            trend = PressureTrend.from(changeHPa: pressure - earlier)
        }

        return WeatherSnapshot(
            time: Date(timeIntervalSince1970: hourly.time[bestIndex]),
            condition: value(hourly.weather_code, bestIndex).map { WeatherCondition.fromWMOCode(Int($0)) },
            airTempC: value(hourly.temperature_2m, bestIndex),
            pressureHPa: pressure,
            pressureTrend: trend,
            windSpeedKmh: value(hourly.wind_speed_10m, bestIndex),
            windGustKmh: value(hourly.wind_gusts_10m, bestIndex),
            windDirectionDeg: value(hourly.wind_direction_10m, bestIndex),
            cloudCoverPct: value(hourly.cloud_cover, bestIndex),
            humidityPct: value(hourly.relative_humidity_2m, bestIndex),
            precipitationMm: value(hourly.precipitation, bestIndex)
        )
    }

    /// Copies fetched weather onto a trip. Without `overwrite`, values typed in by hand win.
    @MainActor
    static func apply(_ snapshot: WeatherSnapshot, to trip: Trip, overwrite: Bool = false) {
        func merge<T>(_ current: T?, _ new: T?) -> T? {
            guard let new else { return current }
            return (overwrite || current == nil) ? new : current
        }
        trip.weather = merge(trip.weather, snapshot.condition)
        trip.airTempC = merge(trip.airTempC, snapshot.airTempC)
        trip.pressureHPa = merge(trip.pressureHPa, snapshot.pressureHPa)
        trip.pressureTrend = merge(trip.pressureTrend, snapshot.pressureTrend)
        trip.windSpeedKmh = merge(trip.windSpeedKmh, snapshot.windSpeedKmh)
        trip.windDirectionDeg = merge(trip.windDirectionDeg, snapshot.windDirectionDeg)
        trip.cloudCoverPct = merge(trip.cloudCoverPct, snapshot.cloudCoverPct)
        trip.humidityPct = merge(trip.humidityPct, snapshot.humidityPct)
        trip.precipitationMm = merge(trip.precipitationMm, snapshot.precipitationMm)
        trip.weatherFetchedAt = .now
    }

    // Field names mirror the Open-Meteo JSON exactly.
    // swiftlint:disable identifier_name
    private struct Response: Decodable {
        let hourly: Hourly
    }

    private struct Hourly: Decodable {
        let time: [Double]
        let temperature_2m: [Double?]?
        let relative_humidity_2m: [Double?]?
        let precipitation: [Double?]?
        let weather_code: [Double?]?
        let cloud_cover: [Double?]?
        let pressure_msl: [Double?]?
        let wind_speed_10m: [Double?]?
        let wind_direction_10m: [Double?]?
        let wind_gusts_10m: [Double?]?
    }
    // swiftlint:enable identifier_name
}
