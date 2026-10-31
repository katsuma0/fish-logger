import Foundation
import Testing
@testable import FishLogger

struct AstronomyTests {
    @Test func fullMoonIsNearlyFullyLit() {
        // Full moon: 2024-06-22 01:08 UTC.
        let moon = Astronomy.moon(on: Date(timeIntervalSince1970: 1_719_018_480))
        #expect(moon.name == .full)
        #expect(moon.illumination > 0.98)
    }

    @Test func newMoonIsDark() {
        // New moon: 2024-04-08 18:21 UTC, the eclipse.
        let moon = Astronomy.moon(on: Date(timeIntervalSince1970: 1_712_600_460))
        #expect(moon.name == .new)
        #expect(moon.illumination < 0.02)
    }

    @Test func torontoSolsticeSunTimes() throws {
        // Toronto, 2024-06-21: sunrise 5:36 EDT, sunset 21:03 EDT.
        let toronto = try #require(TimeZone(identifier: "America/Toronto"))
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = toronto
        let day = try #require(calendar.date(from: DateComponents(year: 2024, month: 6, day: 21, hour: 12)))
        let sun = Astronomy.sunTimes(on: day, latitude: 43.6532, longitude: -79.3832, timeZone: toronto)
        let sunrise = try #require(sun.sunrise)
        let sunset = try #require(sun.sunset)
        let expectedRise = try #require(calendar.date(from: DateComponents(year: 2024, month: 6, day: 21, hour: 5, minute: 36)))
        let expectedSet = try #require(calendar.date(from: DateComponents(year: 2024, month: 6, day: 21, hour: 21, minute: 3)))
        #expect(abs(sunrise.timeIntervalSince(expectedRise)) < 5 * 60)
        #expect(abs(sunset.timeIntervalSince(expectedSet)) < 5 * 60)
    }
}

struct UnitTests {
    @Test func lengthRoundTrips() {
        let unit = LengthUnit.inches
        #expect(abs(unit.toBase(unit.fromBase(45.5)) - 45.5) < 0.0001)
        #expect(abs(LengthUnit.inches.fromBase(2.54) - 1) < 0.0001)
    }

    @Test func pressureConversions() {
        #expect(abs(PressureUnit.kilopascals.fromBase(1013.25) - 101.325) < 0.0001)
        #expect(abs(PressureUnit.inchesOfMercury.fromBase(1013.25) - 29.92) < 0.01)
    }

    @Test func seaLevelPressureAddsAltitude() {
        // About 12 hPa per 100 m near the surface.
        let adjusted = BarometerService.seaLevel(stationHPa: 1000, altitudeM: 100)
        #expect(adjusted > 1011 && adjusted < 1013)
    }

    @Test func pressureTrendThresholds() {
        #expect(PressureTrend.from(changeHPa: 1.5) == .rising)
        #expect(PressureTrend.from(changeHPa: -2) == .falling)
        #expect(PressureTrend.from(changeHPa: 0.4) == .steady)
    }
}
