import Foundation
import SwiftData

/// Which slice of the log the Stats screen looks at.
enum StatsRange: String, CaseIterable, Identifiable {
    case last30Days, thisYear, allTime

    var id: String { rawValue }

    var label: String {
        switch self {
        case .last30Days: "30 days"
        case .thisYear: "This year"
        case .allTime: "All time"
        }
    }

    /// Trips count when their start is at or after `start` and before `end`. Nil means no limit.
    /// The 30 day window is whole days, today included, so a trip this morning never drops out.
    func interval(now: Date, calendar: Calendar) -> DateInterval? {
        switch self {
        case .allTime:
            return nil
        case .thisYear:
            if let year = calendar.dateInterval(of: .year, for: now) {
                return year
            }
            return DateInterval(start: calendar.startOfDay(for: now), duration: 86_400)
        case .last30Days:
            let today = calendar.startOfDay(for: now)
            let start = calendar.date(byAdding: .day, value: -29, to: today) ?? today.addingTimeInterval(-29 * 86_400)
            let end = calendar.date(byAdding: .day, value: 1, to: today) ?? today.addingTimeInterval(86_400)
            return DateInterval(start: start, end: max(start, end))
        }
    }
}

/// Thresholds shared by the calculator and its result types. Kept outside the main actor so
/// plain value types can read them.
enum StatsLimits {
    /// A trip left running overnight would otherwise count as a day and a half of fishing.
    static let maxTripHours: Double = 16
    /// Below this a per-hour rate is mostly noise.
    static let minimumHoursForRate: Double = 0.1
    static let lowPressureHPa: Double = 1005
    static let highPressureHPa: Double = 1022
}

/// Every number on the Stats screen, worked out once from a list of trips.
/// Deterministic for a given input: `now` and `calendar` are injectable for tests.
@MainActor
struct StatsCalculator {
    let range: StatsRange
    let speciesID: String?
    let now: Date
    let calendar: Calendar

    /// Trips that started in range, oldest first. A species filter never removes trips, so
    /// per-hour rates still mean fish of that species per hour fished.
    let trips: [Trip]
    /// Catches on those trips, limited to `speciesID` when set, oldest first.
    let catches: [FishCatch]

    /// Sum of `count`, so a logged school of perch counts as every fish in it.
    let totalFish: Int
    let tripCount: Int
    /// Distinct calendar days with a trip start.
    let daysFished: Int
    /// Distinct species caught, not counting unknown fish.
    let speciesCount: Int
    /// Each trip capped at `StatsLimits.maxTripHours`.
    let hoursFished: Double
    let releasedFish: Int

    /// Most caught first.
    let bySpecies: [SpeciesCount]
    /// Always 24 entries, hour 0 to 23 on `calendar`.
    let byHourOfDay: [HourCount]
    /// Months in range that have trips, oldest first.
    let byMonth: [MonthCount]
    /// All five classes in size order. Fish with no size are left out.
    let sizeClassCounts: [SizeClassCount]
    /// One per species caught, by species name. Unknown fish are left out.
    let personalBests: [PersonalBest]
    /// Up to five spots, most fish first.
    let topSpots: [SpotCount]

    private let facts: [TripFact]

    init(
        trips allTrips: [Trip],
        range: StatsRange = .allTime,
        speciesID: String? = nil,
        now: Date = .now,
        calendar: Calendar = .current
    ) {
        var inRange = allTrips
        if let interval = range.interval(now: now, calendar: calendar) {
            inRange = allTrips.filter { $0.startDate >= interval.start && $0.startDate < interval.end }
        }
        inRange.sort { lhs, rhs in
            if lhs.startDate != rhs.startDate { return lhs.startDate < rhs.startDate }
            return lhs.id.uuidString < rhs.id.uuidString
        }

        var facts: [TripFact] = []
        var filteredCatches: [FishCatch] = []
        facts.reserveCapacity(inRange.count)
        for trip in inRange {
            let tripCatches = trip.catches.filter { speciesID == nil || $0.speciesID == speciesID }
            filteredCatches.append(contentsOf: tripCatches)
            let fish = tripCatches.reduce(0) { $0 + $1.count }
            let seconds = max(0, (trip.endDate ?? now).timeIntervalSince(trip.startDate))
            let hours = min(seconds / 3600, StatsLimits.maxTripHours)
            facts.append(TripFact(trip: trip, fish: fish, hours: hours))
        }
        filteredCatches.sort { $0.timestamp < $1.timestamp }

        let totalFish = filteredCatches.reduce(0) { $0 + $1.count }
        let releasedFish = filteredCatches.reduce(0) { $0 + ($1.released ? $1.count : 0) }
        let days = Set(inRange.map { calendar.startOfDay(for: $0.startDate) })
        let caughtSpecies = Set(filteredCatches.map(\.speciesID)).filter { $0 != SpeciesCatalog.unknownID }

        self.range = range
        self.speciesID = speciesID
        self.now = now
        self.calendar = calendar
        self.trips = inRange
        self.catches = filteredCatches
        self.facts = facts
        self.totalFish = totalFish
        self.releasedFish = releasedFish
        self.tripCount = inRange.count
        self.daysFished = days.count
        self.speciesCount = caughtSpecies.count
        self.hoursFished = facts.reduce(0.0) { $0 + $1.hours }
        self.bySpecies = StatsCalculator.speciesCounts(filteredCatches)
        self.byHourOfDay = StatsCalculator.hourCounts(filteredCatches, calendar: calendar)
        self.byMonth = StatsCalculator.monthCounts(facts, calendar: calendar)
        self.sizeClassCounts = StatsCalculator.sizeCounts(filteredCatches)
        self.personalBests = StatsCalculator.bests(filteredCatches)
        self.topSpots = StatsCalculator.spots(facts)
    }

    // MARK: Rates

    /// Nil when there is not enough time on the water to mean anything.
    var fishPerHour: Double? {
        guard hoursFished >= StatsLimits.minimumHoursForRate else { return nil }
        return Double(totalFish) / hoursFished
    }

    /// Share of trips with no fish, 0 to 1. Nil with no trips.
    var skunkRate: Double? {
        guard !facts.isEmpty else { return nil }
        let skunked = facts.filter { $0.fish == 0 }.count
        return Double(skunked) / Double(facts.count)
    }

    /// Share of fish released, 0 to 1. Nil with no fish.
    var releasedShare: Double? {
        guard totalFish > 0 else { return nil }
        return Double(releasedFish) / Double(totalFish)
    }

    // MARK: Helpers for the screen

    /// Name for a species id, falling back to "Unknown fish" for ids the catalog does not know.
    nonisolated static func speciesName(for speciesID: String) -> String {
        SpeciesCatalog.species(id: speciesID)?.commonName ?? "Unknown fish"
    }

    /// Every species id in the log, by name. Used for the species filter.
    nonisolated static func loggedSpeciesIDs(in trips: [Trip]) -> [String] {
        var ids = Set<String>()
        for trip in trips {
            for fishCatch in trip.catches {
                ids.insert(fishCatch.speciesID)
            }
        }
        return ids.sorted { lhs, rhs in
            let left = speciesName(for: lhs)
            let right = speciesName(for: rhs)
            return left == right ? lhs < rhs : left < right
        }
    }
}

// MARK: Result types

extension StatsCalculator {
    struct SpeciesCount: Identifiable {
        let speciesID: String
        let count: Int

        var id: String { speciesID }
        var species: Species? { SpeciesCatalog.species(id: speciesID) }
        var name: String { StatsCalculator.speciesName(for: speciesID) }
    }

    struct HourCount: Identifiable {
        /// 0 to 23.
        let hour: Int
        let count: Int

        var id: Int { hour }
    }

    struct MonthCount: Identifiable {
        /// Start of the month on the calculator's calendar.
        let month: Date
        let count: Int
        let trips: Int

        var id: Date { month }
    }

    struct SizeClassCount: Identifiable {
        let sizeClass: SizeClass
        let count: Int

        var id: String { sizeClass.rawValue }
    }

    /// Longest and heaviest come only from measured values, never from size class estimates.
    struct PersonalBest: Identifiable {
        let speciesID: String
        var longestCm: Double? = nil
        var heaviestKg: Double? = nil
        var biggestClass: SizeClass? = nil
        var longestCatchDate: Date? = nil
        var heaviestCatchDate: Date? = nil

        var id: String { speciesID }
        var species: Species? { SpeciesCatalog.species(id: speciesID) }
        var name: String { StatsCalculator.speciesName(for: speciesID) }
    }

    struct SpotCount: Identifiable {
        /// The trip's display name, so blank names group as "Unnamed spot".
        let name: String
        let fish: Int
        let trips: Int

        var id: String { name }
    }

    /// Fish per hour for one bucket of a condition. Only trips with the condition recorded count.
    struct ConditionRate: Identifiable {
        let label: String
        let trips: Int
        let hours: Double
        let fish: Int

        var fishPerHour: Double {
            guard hours >= StatsLimits.minimumHoursForRate else { return 0 }
            return Double(fish) / hours
        }

        var id: String { label }
    }

    fileprivate struct TripFact {
        let trip: Trip
        /// Fish on this trip after the species filter.
        let fish: Int
        /// Capped duration.
        let hours: Double
    }
}

// MARK: Aggregation

extension StatsCalculator {
    fileprivate static func speciesCounts(_ catches: [FishCatch]) -> [SpeciesCount] {
        var totals: [String: Int] = [:]
        for fishCatch in catches {
            totals[fishCatch.speciesID, default: 0] += fishCatch.count
        }
        return totals
            .map { SpeciesCount(speciesID: $0.key, count: $0.value) }
            .sorted { lhs, rhs in
                if lhs.count != rhs.count { return lhs.count > rhs.count }
                if lhs.name != rhs.name { return lhs.name < rhs.name }
                return lhs.speciesID < rhs.speciesID
            }
    }

    fileprivate static func hourCounts(_ catches: [FishCatch], calendar: Calendar) -> [HourCount] {
        var totals = Array(repeating: 0, count: 24)
        for fishCatch in catches {
            let hour = calendar.component(.hour, from: fishCatch.timestamp)
            if totals.indices.contains(hour) {
                totals[hour] += fishCatch.count
            }
        }
        return totals.enumerated().map { HourCount(hour: $0.offset, count: $0.element) }
    }

    fileprivate static func monthCounts(_ facts: [TripFact], calendar: Calendar) -> [MonthCount] {
        var fish: [Date: Int] = [:]
        var trips: [Date: Int] = [:]
        for fact in facts {
            let start = fact.trip.startDate
            let month = calendar.dateInterval(of: .month, for: start)?.start ?? calendar.startOfDay(for: start)
            fish[month, default: 0] += fact.fish
            trips[month, default: 0] += 1
        }
        return trips.keys.sorted().map { month in
            MonthCount(month: month, count: fish[month] ?? 0, trips: trips[month] ?? 0)
        }
    }

    fileprivate static func sizeCounts(_ catches: [FishCatch]) -> [SizeClassCount] {
        var totals: [SizeClass: Int] = [:]
        for fishCatch in catches {
            if let size = fishCatch.effectiveSizeClass {
                totals[size, default: 0] += fishCatch.count
            }
        }
        return SizeClass.allCases.map { SizeClassCount(sizeClass: $0, count: totals[$0] ?? 0) }
    }

    fileprivate static func bests(_ catches: [FishCatch]) -> [PersonalBest] {
        var byID: [String: PersonalBest] = [:]
        for fishCatch in catches where fishCatch.speciesID != SpeciesCatalog.unknownID {
            var best = byID[fishCatch.speciesID] ?? PersonalBest(speciesID: fishCatch.speciesID)
            if let length = fishCatch.lengthCm, length > 0, length > (best.longestCm ?? 0) {
                best.longestCm = length
                best.longestCatchDate = fishCatch.timestamp
            }
            if let weight = fishCatch.weightKg, weight > 0, weight > (best.heaviestKg ?? 0) {
                best.heaviestKg = weight
                best.heaviestCatchDate = fishCatch.timestamp
            }
            if let size = fishCatch.effectiveSizeClass {
                best.biggestClass = max(size, best.biggestClass ?? size)
            }
            byID[fishCatch.speciesID] = best
        }
        return byID.values.sorted { lhs, rhs in
            if lhs.name != rhs.name { return lhs.name < rhs.name }
            return lhs.speciesID < rhs.speciesID
        }
    }

    fileprivate static func spots(_ facts: [TripFact]) -> [SpotCount] {
        var fish: [String: Int] = [:]
        var trips: [String: Int] = [:]
        for fact in facts {
            let name = fact.trip.displayName
            fish[name, default: 0] += fact.fish
            trips[name, default: 0] += 1
        }
        let ranked = trips.keys
            .map { SpotCount(name: $0, fish: fish[$0] ?? 0, trips: trips[$0] ?? 0) }
            .sorted { lhs, rhs in
                if lhs.fish != rhs.fish { return lhs.fish > rhs.fish }
                if lhs.trips != rhs.trips { return lhs.trips > rhs.trips }
                return lhs.name < rhs.name
            }
        return Array(ranked.prefix(5))
    }
}

// MARK: Conditions
// These compare fish per hour, not raw counts, because people fish longer on nice days.

extension StatsCalculator {
    /// Uses sea-level pressure. Labels are in hPa unless another unit is passed.
    func ratesByPressureBucket(unit: PressureUnit? = nil) -> [ConditionRate] {
        return groupedRates(order: PressureBucket.allCases, label: { $0.label(unit: unit) }) { (trip: Trip) -> PressureBucket? in
            guard let hPa = trip.pressureHPa else { return nil }
            return PressureBucket(hPa: hPa)
        }
    }

    func ratesByPressureTrend() -> [ConditionRate] {
        return groupedRates(order: PressureTrend.allCases, label: { $0.label }) { (trip: Trip) -> PressureTrend? in
            trip.pressureTrend
        }
    }

    /// The eight named phases folded into New, Waxing, Full, and Waning.
    func ratesByMoon() -> [ConditionRate] {
        return groupedRates(order: MoonGroup.allCases, label: { $0.label }) { (trip: Trip) -> MoonGroup? in
            guard let phase = trip.moonPhase else { return nil }
            return MoonGroup(phase: phase)
        }
    }

    func ratesByWeather() -> [ConditionRate] {
        return groupedRates(order: WeatherCondition.allCases, label: { $0.label }) { (trip: Trip) -> WeatherCondition? in
            trip.weather
        }
    }

    /// Hours on the water are split across morning, midday, evening, and night, and fish go to
    /// the part of the day they were logged in. A trip counts toward every part it overlaps.
    func ratesByTimeOfDay() -> [ConditionRate] {
        var hours: [DayPart: Double] = [:]
        var tripCounts: [DayPart: Int] = [:]
        var fish: [DayPart: Int] = [:]

        for fact in facts where fact.hours > 0 {
            let start = fact.trip.startDate
            let end = start.addingTimeInterval(fact.hours * 3600)
            var touched = Set<DayPart>()
            var dayStart = calendar.startOfDay(for: start)
            var daysChecked = 0
            while dayStart < end && daysChecked < 4 {
                daysChecked += 1
                guard let nextDay = calendar.date(byAdding: .day, value: 1, to: dayStart), nextDay > dayStart else { break }
                for slot in DayPart.slots(dayStart: dayStart, nextDay: nextDay, calendar: calendar) {
                    let overlap = min(end, slot.end).timeIntervalSince(max(start, slot.start))
                    if overlap > 0 {
                        hours[slot.part, default: 0] += overlap / 3600
                        touched.insert(slot.part)
                    }
                }
                dayStart = nextDay
            }
            for part in touched {
                tripCounts[part, default: 0] += 1
            }
        }

        for fishCatch in catches {
            let part = DayPart(hour: calendar.component(.hour, from: fishCatch.timestamp))
            fish[part, default: 0] += fishCatch.count
        }

        return DayPart.allCases.compactMap { part -> ConditionRate? in
            guard let count = tripCounts[part], count > 0 else { return nil }
            return ConditionRate(label: part.label, trips: count, hours: hours[part] ?? 0, fish: fish[part] ?? 0)
        }
    }

    /// Buckets with no trips are left out. Trips without the condition recorded are skipped.
    private func groupedRates<Key: Hashable>(
        order: [Key],
        label: (Key) -> String,
        key: (Trip) -> Key?
    ) -> [ConditionRate] {
        var tripCounts: [Key: Int] = [:]
        var hours: [Key: Double] = [:]
        var fish: [Key: Int] = [:]
        for fact in facts {
            guard let bucket = key(fact.trip) else { continue }
            tripCounts[bucket, default: 0] += 1
            hours[bucket, default: 0] += fact.hours
            fish[bucket, default: 0] += fact.fish
        }
        return order.compactMap { bucket -> ConditionRate? in
            guard let count = tripCounts[bucket], count > 0 else { return nil }
            return ConditionRate(label: label(bucket), trips: count, hours: hours[bucket] ?? 0, fish: fish[bucket] ?? 0)
        }
    }
}

// MARK: Buckets

extension StatsCalculator {
    fileprivate enum PressureBucket: CaseIterable, Hashable {
        case low, normal, high

        init(hPa: Double) {
            if hPa < StatsLimits.lowPressureHPa {
                self = .low
            } else if hPa > StatsLimits.highPressureHPa {
                self = .high
            } else {
                self = .normal
            }
        }

        func label(unit: PressureUnit?) -> String {
            guard let unit, unit != .hectopascals else {
                switch self {
                case .low: return "Low (under 1005 hPa)"
                case .normal: return "Normal"
                case .high: return "High (over 1022 hPa)"
                }
            }
            switch self {
            case .low: return "Low (under \(unit.format(StatsLimits.lowPressureHPa)))"
            case .normal: return "Normal"
            case .high: return "High (over \(unit.format(StatsLimits.highPressureHPa)))"
            }
        }
    }

    fileprivate enum MoonGroup: CaseIterable, Hashable {
        case new, waxing, full, waning

        init(phase: Double) {
            switch MoonInfo.name(forPhase: phase) {
            case .new: self = .new
            case .waxingCrescent, .firstQuarter, .waxingGibbous: self = .waxing
            case .full: self = .full
            case .waningGibbous, .lastQuarter, .waningCrescent: self = .waning
            }
        }

        var label: String {
            switch self {
            case .new: "New"
            case .waxing: "Waxing"
            case .full: "Full"
            case .waning: "Waning"
            }
        }
    }

    fileprivate enum DayPart: CaseIterable, Hashable {
        case morning, midday, evening, night

        /// Morning 5 to 11, midday 11 to 16, evening 16 to 21, night the rest.
        init(hour: Int) {
            switch hour {
            case 5..<11: self = .morning
            case 11..<16: self = .midday
            case 16..<21: self = .evening
            default: self = .night
            }
        }

        var label: String {
            switch self {
            case .morning: "Morning"
            case .midday: "Midday"
            case .evening: "Evening"
            case .night: "Night"
            }
        }

        struct Slot {
            let part: DayPart
            let start: Date
            let end: Date
        }

        /// The five clock slices of one calendar day. Night appears twice, either side of midnight.
        static func slots(dayStart: Date, nextDay: Date, calendar: Calendar) -> [Slot] {
            guard
                let five = calendar.date(bySettingHour: 5, minute: 0, second: 0, of: dayStart),
                let eleven = calendar.date(bySettingHour: 11, minute: 0, second: 0, of: dayStart),
                let sixteen = calendar.date(bySettingHour: 16, minute: 0, second: 0, of: dayStart),
                let twentyOne = calendar.date(bySettingHour: 21, minute: 0, second: 0, of: dayStart)
            else { return [] }
            return [
                Slot(part: .night, start: dayStart, end: five),
                Slot(part: .morning, start: five, end: eleven),
                Slot(part: .midday, start: eleven, end: sixteen),
                Slot(part: .evening, start: sixteen, end: twentyOne),
                Slot(part: .night, start: twentyOne, end: nextDay)
            ]
        }
    }
}
