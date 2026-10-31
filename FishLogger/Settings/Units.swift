import Foundation

/// A display unit for one kind of measurement. Values are always stored in the base unit
/// (cm, kg, °C, hPa, km/h, m) and only converted at the edges.
protocol DisplayUnit: CaseIterable, Identifiable, RawRepresentable where RawValue == String {
    var symbol: String { get }
    var label: String { get }
    /// Decimal places shown by `format`.
    var fractionDigits: Int { get }
    func fromBase(_ value: Double) -> Double
    func toBase(_ value: Double) -> Double
}

extension DisplayUnit {
    var id: String { rawValue }

    /// Formats a base-unit value, e.g. `format(45.5)` gives "45.5 cm" or "17.9 in".
    func format(_ baseValue: Double) -> String {
        "\(Self.number(fromBase(baseValue), digits: fractionDigits)) \(symbol)"
    }

    /// Number only, in display units, no symbol.
    func formatNumber(_ baseValue: Double) -> String {
        Self.number(fromBase(baseValue), digits: fractionDigits)
    }

    static func number(_ value: Double, digits: Int) -> String {
        value.formatted(.number.precision(.fractionLength(0...digits)))
    }
}

enum LengthUnit: String, CaseIterable, DisplayUnit {
    case centimeters, inches
    var symbol: String { self == .centimeters ? "cm" : "in" }
    var label: String { self == .centimeters ? "Centimetres" : "Inches" }
    var fractionDigits: Int { 1 }
    func fromBase(_ cm: Double) -> Double { self == .centimeters ? cm : cm / 2.54 }
    func toBase(_ value: Double) -> Double { self == .centimeters ? value : value * 2.54 }
}

enum WeightUnit: String, CaseIterable, DisplayUnit {
    case kilograms, pounds
    var symbol: String { self == .kilograms ? "kg" : "lb" }
    var label: String { self == .kilograms ? "Kilograms" : "Pounds" }
    var fractionDigits: Int { 2 }
    func fromBase(_ kg: Double) -> Double { self == .kilograms ? kg : kg * 2.204_622_6 }
    func toBase(_ value: Double) -> Double { self == .kilograms ? value : value / 2.204_622_6 }
}

enum TemperatureUnit: String, CaseIterable, DisplayUnit {
    case celsius, fahrenheit
    var symbol: String { self == .celsius ? "°C" : "°F" }
    var label: String { self == .celsius ? "Celsius" : "Fahrenheit" }
    var fractionDigits: Int { 0 }
    func fromBase(_ c: Double) -> Double { self == .celsius ? c : c * 9 / 5 + 32 }
    func toBase(_ value: Double) -> Double { self == .celsius ? value : (value - 32) * 5 / 9 }

    /// Temperatures read better without the space: "18°C".
    func format(_ baseValue: Double) -> String {
        "\(Self.number(fromBase(baseValue), digits: fractionDigits))\(symbol)"
    }
}

enum PressureUnit: String, CaseIterable, DisplayUnit {
    case kilopascals, hectopascals, inchesOfMercury
    var symbol: String {
        switch self {
        case .kilopascals: "kPa"
        case .hectopascals: "hPa"
        case .inchesOfMercury: "inHg"
        }
    }
    var label: String {
        switch self {
        case .kilopascals: "Kilopascals"
        case .hectopascals: "Hectopascals (millibars)"
        case .inchesOfMercury: "Inches of mercury"
        }
    }
    var fractionDigits: Int {
        switch self {
        case .kilopascals: 1
        case .hectopascals: 0
        case .inchesOfMercury: 2
        }
    }
    func fromBase(_ hPa: Double) -> Double {
        switch self {
        case .kilopascals: hPa / 10
        case .hectopascals: hPa
        case .inchesOfMercury: hPa * 0.029_529_983
        }
    }
    func toBase(_ value: Double) -> Double {
        switch self {
        case .kilopascals: value * 10
        case .hectopascals: value
        case .inchesOfMercury: value / 0.029_529_983
        }
    }
}

enum SpeedUnit: String, CaseIterable, DisplayUnit {
    case kilometresPerHour, milesPerHour
    var symbol: String { self == .kilometresPerHour ? "km/h" : "mph" }
    var label: String { self == .kilometresPerHour ? "Kilometres per hour" : "Miles per hour" }
    var fractionDigits: Int { 0 }
    func fromBase(_ kmh: Double) -> Double { self == .kilometresPerHour ? kmh : kmh / 1.609_344 }
    func toBase(_ value: Double) -> Double { self == .kilometresPerHour ? value : value * 1.609_344 }
}

enum DepthUnit: String, CaseIterable, DisplayUnit {
    case meters, feet
    var symbol: String { self == .meters ? "m" : "ft" }
    var label: String { self == .meters ? "Metres" : "Feet" }
    var fractionDigits: Int { 1 }
    func fromBase(_ m: Double) -> Double { self == .meters ? m : m * 3.280_84 }
    func toBase(_ value: Double) -> Double { self == .meters ? value : value / 3.280_84 }
}

enum Compass {
    /// "NW" style label for a wind direction in degrees.
    static func label(forDegrees degrees: Double) -> String {
        let points = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        let normalized = (degrees.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360)
        let index = Int((normalized + 22.5) / 45) % 8
        return points[index]
    }
}
