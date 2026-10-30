import Foundation

/// Rough size buckets for days when measuring every fish is not worth it.
/// Each species maps these to its own length ranges (see `Species.sizeCutoffsCm`).
enum SizeClass: String, CaseIterable, Codable, Identifiable, Comparable {
    case dink, small, medium, large, trophy

    var id: String { rawValue }

    var label: String {
        switch self {
        case .dink: "Dink"
        case .small: "Small"
        case .medium: "Medium"
        case .large: "Large"
        case .trophy: "Trophy"
        }
    }

    var rank: Int { Self.allCases.firstIndex(of: self) ?? 0 }

    var symbolName: String {
        switch self {
        case .dink: "circle.fill"
        case .small: "circle.lefthalf.filled"
        case .medium: "circle.circle.fill"
        case .large: "seal.fill"
        case .trophy: "trophy.fill"
        }
    }

    static func < (lhs: SizeClass, rhs: SizeClass) -> Bool { lhs.rank < rhs.rank }
}

enum WeatherCondition: String, CaseIterable, Codable, Identifiable {
    case sunny, partlyCloudy, overcast, fog, drizzle, rain, storm, snow, windy

    var id: String { rawValue }

    var label: String {
        switch self {
        case .sunny: "Sunny"
        case .partlyCloudy: "Partly cloudy"
        case .overcast: "Overcast"
        case .fog: "Fog"
        case .drizzle: "Drizzle"
        case .rain: "Rain"
        case .storm: "Storm"
        case .snow: "Snow"
        case .windy: "Windy"
        }
    }

    var symbolName: String {
        switch self {
        case .sunny: "sun.max.fill"
        case .partlyCloudy: "cloud.sun.fill"
        case .overcast: "cloud.fill"
        case .fog: "cloud.fog.fill"
        case .drizzle: "cloud.drizzle.fill"
        case .rain: "cloud.rain.fill"
        case .storm: "cloud.bolt.rain.fill"
        case .snow: "cloud.snow.fill"
        case .windy: "wind"
        }
    }

    /// Maps WMO weather interpretation codes (used by Open-Meteo) to our smaller set.
    static func fromWMOCode(_ code: Int) -> WeatherCondition {
        switch code {
        case 0: .sunny
        case 1, 2: .partlyCloudy
        case 3: .overcast
        case 45, 48: .fog
        case 51...57: .drizzle
        case 61...67, 80...82: .rain
        case 71...77, 85, 86: .snow
        case 95...99: .storm
        default: .overcast
        }
    }
}

enum PressureTrend: String, CaseIterable, Codable, Identifiable {
    case rising, steady, falling

    var id: String { rawValue }

    var label: String {
        switch self {
        case .rising: "Rising"
        case .steady: "Steady"
        case .falling: "Falling"
        }
    }

    var symbolName: String {
        switch self {
        case .rising: "arrow.up.right"
        case .steady: "arrow.right"
        case .falling: "arrow.down.right"
        }
    }

    /// Change over roughly three hours. Anything inside +/- 1 hPa reads as steady,
    /// which is close to the noise floor of both phone barometers and forecast models.
    static func from(changeHPa: Double) -> PressureTrend {
        if changeHPa >= 1 { return .rising }
        if changeHPa <= -1 { return .falling }
        return .steady
    }
}

enum WaterClarity: String, CaseIterable, Codable, Identifiable {
    case clear, stained, murky, muddy

    var id: String { rawValue }

    var label: String {
        switch self {
        case .clear: "Clear"
        case .stained: "Stained"
        case .murky: "Murky"
        case .muddy: "Muddy"
        }
    }
}

enum WaterLevel: String, CaseIterable, Codable, Identifiable {
    case low, normal, high

    var id: String { rawValue }

    var label: String {
        switch self {
        case .low: "Low"
        case .normal: "Normal"
        case .high: "High"
        }
    }
}

enum WaterBodyType: String, CaseIterable, Codable, Identifiable {
    case lake, river, creek, pond, reservoir, bay, other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .lake: "Lake"
        case .river: "River"
        case .creek: "Creek"
        case .pond: "Pond"
        case .reservoir: "Reservoir"
        case .bay: "Bay"
        case .other: "Other"
        }
    }

    var symbolName: String {
        switch self {
        case .lake, .pond, .reservoir: "water.waves"
        case .river, .creek: "drop.fill"
        case .bay: "sailboat.fill"
        case .other: "mappin.and.ellipse"
        }
    }
}

enum FishingMethod: String, CaseIterable, Codable, Identifiable {
    case shore, boat, kayak, wading, ice, pier

    var id: String { rawValue }

    var label: String {
        switch self {
        case .shore: "Shore"
        case .boat: "Boat"
        case .kayak: "Kayak"
        case .wading: "Wading"
        case .ice: "Ice"
        case .pier: "Pier or dock"
        }
    }

    var symbolName: String {
        switch self {
        case .shore: "figure.fishing"
        case .boat: "ferry.fill"
        case .kayak: "figure.water.fitness"
        case .wading: "figure.walk"
        case .ice: "snowflake"
        case .pier: "rectangle.split.3x1.fill"
        }
    }
}

/// How a catch's species was decided. Kept so stats can show how often the AI was trusted.
enum IdentificationSource: String, CaseIterable, Codable, Identifiable {
    case manual, claude, onDevice, traitKey

    var id: String { rawValue }

    var label: String {
        switch self {
        case .manual: "Picked by hand"
        case .claude: "Claude photo ID"
        case .onDevice: "On-device model"
        case .traitKey: "Feature checklist"
        }
    }
}
