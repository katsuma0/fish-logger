import Foundation
import Testing
@testable import FishLogger

/// Parsing of Open-Meteo hourly data, as fetched with `timeformat=unixtime`.
struct WeatherTests {
    /// The first hour in the sample.
    private static let start: TimeInterval = 1_781_000_000

    /// Four hours of data. The third hour is missing its temperature, which Open-Meteo sends as null.
    private static let sample = Data("""
    {
      "latitude": 44.4,
      "longitude": -79.4,
      "hourly_units": {"time": "unixtime", "temperature_2m": "°C", "pressure_msl": "hPa"},
      "hourly": {
        "time": [1781000000, 1781003600, 1781007200, 1781010800],
        "temperature_2m": [10.0, 11.0, null, 13.0],
        "relative_humidity_2m": [80, 75, 70, 65],
        "precipitation": [0.0, 0.0, 0.2, 0.0],
        "weather_code": [0, 2, 61, 3],
        "cloud_cover": [0, 40, 90, 100],
        "pressure_msl": [1015.0, 1014.0, 1013.0, 1012.0],
        "wind_speed_10m": [5.0, 8.0, 12.0, 10.0],
        "wind_direction_10m": [180, 190, 200, 210],
        "wind_gusts_10m": [10.0, 15.0, 20.0, 18.0]
      }
    }
    """.utf8)

    private static func hour(_ offset: Double) -> Date {
        Date(timeIntervalSince1970: start + offset * 3600)
    }

    @Test func picksTheHourClosestToTheTime() throws {
        let snapshot = try WeatherService.parse(Self.sample, at: Self.hour(3).addingTimeInterval(10 * 60))
        #expect(snapshot.time == Self.hour(3))
        #expect(snapshot.airTempC == 13.0)
        #expect(snapshot.condition == .overcast)
        #expect(snapshot.windSpeedKmh == 10.0)
        #expect(snapshot.windGustKmh == 18.0)
        #expect(snapshot.windDirectionDeg == 210)
        #expect(snapshot.cloudCoverPct == 100)
        #expect(snapshot.humidityPct == 65)
        #expect(snapshot.precipitationMm == 0)
    }

    @Test func pressureTrendComparesThreeHoursEarlier() throws {
        // 1012 now against 1015 three hours before.
        let snapshot = try WeatherService.parse(Self.sample, at: Self.hour(3))
        #expect(snapshot.pressureHPa == 1012)
        #expect(snapshot.pressureTrend == .falling)
    }

    @Test func noTrendWithoutAReadingThreeHoursBefore() throws {
        let snapshot = try WeatherService.parse(Self.sample, at: Self.hour(1))
        #expect(snapshot.condition == .partlyCloudy)
        #expect(snapshot.pressureHPa == 1014)
        #expect(snapshot.pressureTrend == nil)
    }

    @Test func nullReadingStaysNil() throws {
        let snapshot = try WeatherService.parse(Self.sample, at: Self.hour(2))
        #expect(snapshot.airTempC == nil)
        #expect(snapshot.condition == .rain)
        #expect(snapshot.precipitationMm == 0.2)
    }

    @Test func timeFarFromTheDataIsNoData() {
        #expect(throws: WeatherError.noData) {
            try WeatherService.parse(Self.sample, at: Self.hour(10))
        }
    }

    @Test func emptyHoursAreNoData() {
        let empty = Data(#"{"hourly": {"time": []}}"#.utf8)
        #expect(throws: WeatherError.noData) {
            try WeatherService.parse(empty, at: Self.hour(0))
        }
    }

    @Test func malformedJSONIsABadResponse() {
        #expect(throws: WeatherError.badResponse) {
            try WeatherService.parse(Data("not json".utf8), at: Self.hour(0))
        }
    }
}
