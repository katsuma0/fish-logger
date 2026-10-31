import Foundation
import SwiftData

/// Made-up trips so History and Stats have something to show before a real season is logged.
/// Every sample trip's notes start with `marker`, which is how they are found and removed later.
@MainActor
enum SampleData {
    static let marker = "[sample]"

    /// How far back sample trips go.
    static let spanDays = 60

    static func isSample(_ trip: Trip) -> Bool { trip.notes.hasPrefix(marker) }

    static func sampleTrips(in context: ModelContext) -> [Trip] {
        let trips = (try? context.fetch(FetchDescriptor<Trip>())) ?? []
        return trips.filter { isSample($0) }
    }

    /// Builds trips directly instead of through `CatchLogger.startTrip`, which would end a real
    /// active trip and stamp the current GPS fix on every sample.
    static func addSampleTrips(in context: ModelContext, count: Int = 20, now: Date = .now) {
        let tripCount = max(0, count)
        guard tripCount > 0 else { return }

        // Mixing in the existing sample count means a second tap adds different trips, while the
        // same starting state always produces the same log.
        let existing = UInt64(sampleTrips(in: context).count)
        var random = SampleRandom(seed: 0x00F1_5B10_66E2_2026 &+ existing &* 7919)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        let slot = Double(spanDays) / Double(tripCount)

        for index in 0..<tripCount {
            let jitter = Int.random(in: 0..<max(1, Int(slot)), using: &random)
            let daysAgo = min(spanDays, 1 + Int(Double(index) * slot) + jitter)
            guard let day = calendar.date(byAdding: .day, value: -daysAgo, to: today) else { continue }
            let spot = spots[Int.random(in: 0..<spots.count, using: &random)]
            makeTrip(at: spot, on: day, now: now, calendar: calendar, random: &random, in: context)
        }
        CatchLogger.save(context)
    }

    static func deleteSampleTrips(in context: ModelContext) {
        for trip in sampleTrips(in: context) {
            CatchLogger.delete(trip, in: context)
        }
    }

    // MARK: Trip and catch builders

    private static func makeTrip(
        at spot: SampleSpot,
        on day: Date,
        now: Date,
        calendar: Calendar,
        random: inout SampleRandom,
        in context: ModelContext
    ) {
        let noon = calendar.date(byAdding: .hour, value: 12, to: day) ?? day
        let sun = Astronomy.sunTimes(on: noon, latitude: spot.latitude, longitude: spot.longitude)
        let sunrise = sun.sunrise ?? day.addingTimeInterval(7 * 3600)
        let sunset = sun.sunset ?? day.addingTimeInterval(18 * 3600)

        let atDawn = Bool.random(using: &random)
        let hours: Double
        let rawStart: Date
        if atDawn {
            hours = Double.random(in: 2...7, using: &random)
            rawStart = sunrise.addingTimeInterval(Double.random(in: -45...15, using: &random) * 60)
        } else {
            // Late afternoon start, fishing into the evening bite.
            hours = Double.random(in: 2...4.5, using: &random)
            let hoursBeforeSunset = Double.random(in: 1.5...3.5, using: &random)
            rawStart = sunset.addingTimeInterval(-hoursBeforeSunset * 3600)
        }
        let start = roundedToFiveMinutes(rawStart)
        let end = min(start.addingTimeInterval(hours * 3600), now)
        guard end > start else { return }

        let method = spot.methods[Int.random(in: 0..<spot.methods.count, using: &random)]
        let trip = Trip(
            startDate: start,
            locationName: spot.name,
            latitude: spot.latitude,
            longitude: spot.longitude,
            waterBody: spot.waterBody,
            method: method
        )
        trip.endDate = end

        // Rough Ontario seasonal curve: warmest water in late July, coldest in late January.
        let dayOfYear = Double(calendar.ordinality(of: .day, in: .year, for: day) ?? 180)
        let seasonal = 12 + 10 * sin(2 * Double.pi * (dayOfYear - 120) / 365)
        let waterTemp = max(1, seasonal + Double.random(in: -1.5...1.5, using: &random))
        if waterTemp < 4 { trip.method = .ice }
        // Dawn air is usually colder than the water in fishing season; afternoons run warmer.
        let airOffset: Double
        if atDawn {
            airOffset = Double.random(in: -7...1, using: &random)
        } else {
            airOffset = Double.random(in: -2...7, using: &random)
        }
        trip.waterTempC = rounded(waterTemp, places: 1)
        trip.airTempC = rounded(waterTemp + airOffset, places: 1)

        let weather = weatherChoices[Int.random(in: 0..<weatherChoices.count, using: &random)]
        trip.weather = weather
        trip.cloudCoverPct = cloudCover(for: weather, random: &random)
        trip.humidityPct = Double(Int.random(in: 50...95, using: &random))
        if weather == .rain || weather == .drizzle || weather == .storm {
            trip.precipitationMm = rounded(Double.random(in: 0.2...4, using: &random), places: 1)
        } else {
            trip.precipitationMm = 0
        }

        let pressure = Double.random(in: 995...1030, using: &random)
        trip.pressureHPa = rounded(pressure, places: 1)
        trip.pressureTrend = trend(forPressure: pressure, random: &random)

        let windBase: Double = weather == .windy ? 24 : 3
        trip.windSpeedKmh = rounded(windBase + Double.random(in: 0...18, using: &random), places: 0)
        trip.windDirectionDeg = Double(Int.random(in: 0..<36, using: &random) * 10)
        trip.waterClarity = clarities[Int.random(in: 0..<clarities.count, using: &random)]
        let levelRoll = Double.random(in: 0..<1, using: &random)
        trip.waterLevel = levelRoll < 0.8 ? WaterLevel.normal : WaterLevel.low

        trip.moonPhase = Astronomy.moon(on: start).phase
        trip.sunrise = sun.sunrise
        trip.sunset = sun.sunset

        let note = tripNotes[Int.random(in: 0..<tripNotes.count, using: &random)]
        trip.notes = note.isEmpty ? marker : "\(marker) \(note)"

        context.insert(trip)

        let skunked = Double.random(in: 0..<1, using: &random) < 0.15
        let catchCount = skunked ? 0 : Int.random(in: 1...9, using: &random)
        let window = end.timeIntervalSince(start)
        var times: [Date] = []
        for _ in 0..<catchCount {
            times.append(start.addingTimeInterval(Double.random(in: 0.05...0.95, using: &random) * window))
        }
        times.sort()
        for time in times {
            addCatch(to: trip, at: spot, time: time, random: &random, in: context)
        }
    }

    private static func addCatch(
        to trip: Trip,
        at spot: SampleSpot,
        time: Date,
        random: inout SampleRandom,
        in context: ModelContext
    ) {
        let speciesID = spot.speciesIDs[Int.random(in: 0..<spot.speciesIDs.count, using: &random)]
        guard let species = SpeciesCatalog.species(id: speciesID) else { return }

        let schools = speciesID == "yellow_perch" || speciesID == "black_crappie"
        var count = 1
        if schools, Double.random(in: 0..<1, using: &random) < 0.3 {
            count = Int.random(in: 2...5, using: &random)
        }

        let sizeClass = weightedSizeClass(random: &random)
        let measured = Double.random(in: 0..<1, using: &random) < 0.45
        var lengthCm: Double?
        var weightKg: Double?
        if measured {
            let range = species.lengthRange(for: sizeClass)
            let upper = range.upper ?? (range.lower ?? 50) * 1.25
            let lower = range.lower ?? upper * 0.55
            let top = max(lower + 0.5, upper - 0.5)
            let length = (Double.random(in: lower...top, using: &random) * 2).rounded() / 2
            lengthCm = length
            if Bool.random(using: &random), let estimate = species.estimatedWeightKg(lengthCm: length) {
                let scatter = Double.random(in: 0.9...1.1, using: &random)
                weightKg = max(0.01, rounded(estimate * scatter, places: 2))
            }
        }

        let fishCatch = FishCatch(
            speciesID: species.id,
            timestamp: time,
            count: count,
            sizeClass: measured ? nil : sizeClass,
            lengthCm: lengthCm,
            weightKg: weightKg
        )

        // Panfish and walleye in the slot get kept now and then; bass and muskie go back.
        let keepRate: Double
        switch speciesID {
        case "walleye", "yellow_perch", "black_crappie":
            keepRate = (sizeClass >= .small && sizeClass <= .large) ? 0.45 : 0
        case "northern_pike", "rainbow_trout":
            keepRate = 0.1
        default:
            keepRate = 0
        }
        fishCatch.released = Double.random(in: 0..<1, using: &random) >= keepRate

        if let options = lures[speciesID], !options.isEmpty {
            fishCatch.lure = options[Int.random(in: 0..<options.count, using: &random)]
        }
        if Double.random(in: 0..<1, using: &random) < 0.6 {
            let maxDepth: Double = spot.waterBody == .river ? 2.5 : 9
            fishCatch.depthM = (Double.random(in: 0.5...maxDepth, using: &random) * 2).rounded() / 2
        }

        // Uniform spread over a disc about 300 m across the spot, so map pins do not stack.
        let distance = 300 * Double.random(in: 0...1, using: &random).squareRoot()
        let bearing = Double.random(in: 0..<(2 * Double.pi), using: &random)
        let metresPerDegree = 111_320.0
        let latitudeRadians = spot.latitude * Double.pi / 180
        fishCatch.latitude = spot.latitude + distance * cos(bearing) / metresPerDegree
        fishCatch.longitude = spot.longitude + distance * sin(bearing) / (metresPerDegree * cos(latitudeRadians))

        if Double.random(in: 0..<1, using: &random) < 0.7, let base = trip.pressureHPa {
            fishCatch.pressureHPa = rounded(base + Double.random(in: -1.2...1.2, using: &random), places: 1)
        }
        fishCatch.waterTempC = trip.waterTempC
        fishCatch.identifiedBy = .manual

        context.insert(fishCatch)
        fishCatch.trip = trip
    }

    // MARK: Helpers

    private static func weightedSizeClass(random: inout SampleRandom) -> SizeClass {
        let roll = Double.random(in: 0..<1, using: &random)
        switch roll {
        case ..<0.15: return .dink
        case ..<0.45: return .small
        case ..<0.80: return .medium
        case ..<0.95: return .large
        default: return .trophy
        }
    }

    private static func trend(forPressure pressure: Double, random: inout SampleRandom) -> PressureTrend {
        let roll = Double.random(in: 0..<1, using: &random)
        if pressure < 1008 {
            if roll < 0.6 { return .falling }
            return roll < 0.85 ? .steady : .rising
        }
        if pressure > 1020 {
            if roll < 0.5 { return .steady }
            return roll < 0.8 ? .rising : .falling
        }
        if roll < 0.4 { return .steady }
        return roll < 0.7 ? .rising : .falling
    }

    private static func cloudCover(for weather: WeatherCondition, random: inout SampleRandom) -> Double {
        let range: ClosedRange<Double>
        switch weather {
        case .sunny: range = 0...15
        case .partlyCloudy, .windy: range = 25...60
        case .overcast, .fog, .drizzle, .rain, .storm, .snow: range = 80...100
        }
        return Double.random(in: range, using: &random).rounded()
    }

    private static func rounded(_ value: Double, places: Int) -> Double {
        let factor = pow(10, Double(places))
        return (value * factor).rounded() / factor
    }

    private static func roundedToFiveMinutes(_ date: Date) -> Date {
        let step: TimeInterval = 300
        return Date(timeIntervalSinceReferenceDate: (date.timeIntervalSinceReferenceDate / step).rounded() * step)
    }

    // MARK: Data

    // Species lists repeat ids to weight them toward what each water is known for.
    private static let spots: [SampleSpot] = [
        SampleSpot(
            name: "Lake Simcoe, Keswick",
            latitude: 44.23, longitude: -79.47,
            waterBody: .lake,
            methods: [.boat, .boat, .shore, .pier],
            speciesIDs: ["yellow_perch", "yellow_perch", "yellow_perch", "smallmouth_bass", "smallmouth_bass",
                         "northern_pike", "walleye"]
        ),
        SampleSpot(
            name: "Rice Lake",
            latitude: 44.18, longitude: -78.18,
            waterBody: .lake,
            methods: [.boat, .boat, .kayak],
            speciesIDs: ["walleye", "walleye", "largemouth_bass", "largemouth_bass", "black_crappie",
                         "black_crappie", "muskellunge", "yellow_perch"]
        ),
        SampleSpot(
            name: "Bay of Quinte",
            latitude: 44.15, longitude: -77.30,
            waterBody: .bay,
            methods: [.boat, .boat, .shore],
            speciesIDs: ["walleye", "walleye", "walleye", "walleye", "yellow_perch", "yellow_perch",
                         "northern_pike", "largemouth_bass"]
        ),
        SampleSpot(
            name: "Lake Scugog",
            latitude: 44.15, longitude: -78.85,
            waterBody: .lake,
            methods: [.boat, .kayak, .shore],
            speciesIDs: ["largemouth_bass", "largemouth_bass", "largemouth_bass", "black_crappie", "black_crappie",
                         "walleye", "muskellunge", "yellow_perch"]
        ),
        SampleSpot(
            name: "Credit River",
            latitude: 43.58, longitude: -79.71,
            waterBody: .river,
            methods: [.wading, .wading, .shore],
            speciesIDs: ["rainbow_trout", "rainbow_trout", "rainbow_trout", "rainbow_trout", "smallmouth_bass",
                         "smallmouth_bass"]
        ),
        SampleSpot(
            name: "Lake Nipissing",
            latitude: 46.27, longitude: -79.80,
            waterBody: .lake,
            methods: [.boat],
            speciesIDs: ["walleye", "walleye", "walleye", "walleye", "northern_pike", "northern_pike",
                         "yellow_perch", "yellow_perch", "smallmouth_bass", "muskellunge"]
        ),
        SampleSpot(
            name: "Sturgeon Lake, Kawartha Lakes",
            latitude: 44.45, longitude: -78.72,
            waterBody: .lake,
            methods: [.boat, .boat, .pier],
            speciesIDs: ["walleye", "walleye", "muskellunge", "largemouth_bass", "smallmouth_bass",
                         "black_crappie", "yellow_perch"]
        )
    ]

    private static let weatherChoices: [WeatherCondition] = [
        .sunny, .sunny, .sunny, .partlyCloudy, .partlyCloudy, .partlyCloudy,
        .overcast, .overcast, .drizzle, .rain, .fog, .windy
    ]

    private static let clarities: [WaterClarity] = [.clear, .clear, .stained, .stained, .murky]

    private static let tripNotes: [String] = [
        "Slow until the wind picked up.",
        "Fish were holding on the weed edge.",
        "Bite turned on near sunset.",
        "Lots of small ones.",
        "Marked fish but they would not commit.",
        "Calm and glassy most of the morning.",
        ""
    ]

    private static let lures: [String: [String]] = [
        "walleye": ["Jig and minnow", "Bottom bouncer and crawler", "Crankbait"],
        "yellow_perch": ["Small jig", "Minnow under a float", "Drop shot"],
        "northern_pike": ["Spoon", "Spinnerbait", "Jerkbait"],
        "smallmouth_bass": ["Tube jig", "Drop shot", "Ned rig"],
        "largemouth_bass": ["Texas-rigged worm", "Spinnerbait", "Topwater frog"],
        "black_crappie": ["Small jig", "Minnow under a float"],
        "rainbow_trout": ["Roe bag", "Inline spinner", "Worm under a float"],
        "muskellunge": ["Bucktail", "Jerkbait", "Glide bait"]
    ]
}

private struct SampleSpot {
    let name: String
    let latitude: Double
    let longitude: Double
    let waterBody: WaterBodyType
    let methods: [FishingMethod]
    let speciesIDs: [String]
}

/// SplitMix64. Tiny, fast, and the same sequence on every device, so sample logs are reproducible.
private struct SampleRandom: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
