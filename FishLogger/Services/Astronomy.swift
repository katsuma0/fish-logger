import Foundation

struct MoonInfo: Equatable {
    /// 0 new, 0.25 first quarter, 0.5 full, 0.75 last quarter.
    let phase: Double
    /// Lit fraction of the disc, 0 to 1.
    let illumination: Double

    enum Name: String, CaseIterable {
        case new, waxingCrescent, firstQuarter, waxingGibbous, full, waningGibbous, lastQuarter, waningCrescent

        var label: String {
            switch self {
            case .new: "New moon"
            case .waxingCrescent: "Waxing crescent"
            case .firstQuarter: "First quarter"
            case .waxingGibbous: "Waxing gibbous"
            case .full: "Full moon"
            case .waningGibbous: "Waning gibbous"
            case .lastQuarter: "Last quarter"
            case .waningCrescent: "Waning crescent"
            }
        }

        var symbolName: String {
            switch self {
            case .new: "moonphase.new.moon"
            case .waxingCrescent: "moonphase.waxing.crescent"
            case .firstQuarter: "moonphase.first.quarter"
            case .waxingGibbous: "moonphase.waxing.gibbous"
            case .full: "moonphase.full.moon"
            case .waningGibbous: "moonphase.waning.gibbous"
            case .lastQuarter: "moonphase.last.quarter"
            case .waningCrescent: "moonphase.waning.crescent"
            }
        }
    }

    /// Principal phases get a window of about a day either side; the rest is in between.
    var name: Name { Self.name(forPhase: phase) }

    static func name(forPhase phase: Double) -> Name {
        let day = 1 / Astronomy.synodicMonthDays
        switch phase {
        case ..<day: return .new
        case ..<(0.25 - day): return .waxingCrescent
        case ..<(0.25 + day): return .firstQuarter
        case ..<(0.5 - day): return .waxingGibbous
        case ..<(0.5 + day): return .full
        case ..<(0.75 - day): return .waningGibbous
        case ..<(0.75 + day): return .lastQuarter
        case ..<(1 - day): return .waningCrescent
        default: return .new
        }
    }
}

/// Offline moon and sun math. Accurate to a few minutes, which is plenty for fishing.
enum Astronomy {
    static let synodicMonthDays = 29.530_588_853
    /// A known new moon: 2000-01-06 18:14 UTC.
    private static let referenceNewMoon = Date(timeIntervalSince1970: 947_182_440)
    /// J2000.0 epoch, 2000-01-01 12:00 UTC.
    private static let j2000 = Date(timeIntervalSince1970: 946_728_000)

    static func moon(on date: Date) -> MoonInfo {
        let days = date.timeIntervalSince(referenceNewMoon) / 86_400
        var phase = (days / synodicMonthDays).truncatingRemainder(dividingBy: 1)
        if phase < 0 { phase += 1 }
        let illumination = (1 - cos(2 * .pi * phase)) / 2
        return MoonInfo(phase: phase, illumination: illumination)
    }

    /// Sunrise and sunset on the local calendar day containing `date`. Nil for polar day or night.
    static func sunTimes(
        on date: Date,
        latitude: Double,
        longitude: Double,
        timeZone: TimeZone = .current
    ) -> (sunrise: Date?, sunset: Date?) {
        var localCalendar = Calendar(identifier: .gregorian)
        localCalendar.timeZone = timeZone
        let parts = localCalendar.dateComponents([.year, .month, .day], from: date)

        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(identifier: "UTC")!
        var noonUTC = DateComponents()
        noonUTC.year = parts.year
        noonUTC.month = parts.month
        noonUTC.day = parts.day
        noonUTC.hour = 12
        guard let dayNoon = utcCalendar.date(from: noonUTC) else { return (nil, nil) }

        // Sunrise equation, as laid out by NOAA and the Astronomical Almanac.
        let dayNumber = (dayNoon.timeIntervalSince(j2000) / 86_400).rounded()
        let meanSolarNoon = dayNumber - longitude / 360
        let meanAnomaly = normalizedDegrees(357.5291 + 0.985_600_28 * meanSolarNoon)
        let m = radians(meanAnomaly)
        let center = 1.9148 * sin(m) + 0.0200 * sin(2 * m) + 0.0003 * sin(3 * m)
        let eclipticLongitude = normalizedDegrees(meanAnomaly + center + 180 + 102.9372)
        let lambda = radians(eclipticLongitude)
        let transit = meanSolarNoon + 0.0053 * sin(m) - 0.0069 * sin(2 * lambda)

        let declination = asin(sin(lambda) * sin(radians(23.4397)))
        let phi = radians(latitude)
        let cosHourAngle = (sin(radians(-0.833)) - sin(phi) * sin(declination)) / (cos(phi) * cos(declination))
        guard cosHourAngle >= -1, cosHourAngle <= 1 else { return (nil, nil) }
        let hourAngleDays = degrees(acos(cosHourAngle)) / 360

        let sunrise = j2000.addingTimeInterval((transit - hourAngleDays) * 86_400)
        let sunset = j2000.addingTimeInterval((transit + hourAngleDays) * 86_400)
        return (sunrise, sunset)
    }

    private static func radians(_ degrees: Double) -> Double { degrees * .pi / 180 }
    private static func degrees(_ radians: Double) -> Double { radians * 180 / .pi }
    private static func normalizedDegrees(_ value: Double) -> Double {
        let result = value.truncatingRemainder(dividingBy: 360)
        return result < 0 ? result + 360 : result
    }
}
