import Foundation
import SwiftData
import Testing
@testable import FishLogger

/// Stats over a small hand-made log in a throwaway store. Dates are UTC and `now` is fixed, so the
/// numbers never depend on the clock or the simulator's time zone.
@MainActor
struct StatsTests {
    /// Held by the suite so it outlives every model a test touches.
    let container: ModelContainer
    var context: ModelContext { container.mainContext }

    init() {
        container = AppModelContainer.inMemory()
    }

    // MARK: The log

    /// The trips most tests share, all in 2026:
    /// - June 10, 6 to 9 am at Lake Simcoe: a 55 cm walleye on a "Jig", released, and four small
    ///   yellow perch on a " jig", kept.
    /// - July 2, 6 to 8 pm at Lake Simcoe: a 62 cm, 2.4 kg walleye on a "Crankbait", released.
    /// - July 15, 5 to 6 am at Bass Pond: no fish.
    private struct Log {
        let june: Trip
        let julyEvening: Trip
        let skunk: Trip
        let bigWalleye: FishCatch

        var trips: [Trip] { [june, julyEvening, skunk] }
    }

    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()

    /// A time in 2026, UTC.
    private func date(_ month: Int, _ day: Int, _ hour: Int, _ minute: Int = 0) throws -> Date {
        let components = DateComponents(year: 2026, month: month, day: day, hour: hour, minute: minute)
        return try #require(Self.calendar.date(from: components))
    }

    private func makeTrip(from start: Date, to end: Date?, at spot: String) -> Trip {
        let trip = Trip(startDate: start, locationName: spot)
        trip.endDate = end
        context.insert(trip)
        return trip
    }

    private func add(_ fishCatch: FishCatch, to trip: Trip, lure: String = "") {
        fishCatch.lure = lure
        context.insert(fishCatch)
        fishCatch.trip = trip
    }

    private func makeLog() throws -> Log {
        let june = try makeTrip(from: date(6, 10, 6), to: date(6, 10, 9), at: "Lake Simcoe")
        let julyEvening = try makeTrip(from: date(7, 2, 18), to: date(7, 2, 20), at: "Lake Simcoe")
        let skunk = try makeTrip(from: date(7, 15, 5), to: date(7, 15, 6), at: "Bass Pond")

        try add(FishCatch(speciesID: "walleye", timestamp: date(6, 10, 7, 15), lengthCm: 55), to: june, lure: "Jig")
        let perch = try FishCatch(speciesID: "yellow_perch", timestamp: date(6, 10, 8, 30), count: 4, sizeClass: .small)
        perch.released = false
        add(perch, to: june, lure: " jig")
        let bigWalleye = try FishCatch(speciesID: "walleye", timestamp: date(7, 2, 19), lengthCm: 62, weightKg: 2.4)
        add(bigWalleye, to: julyEvening, lure: "Crankbait")

        try context.save()
        return Log(june: june, julyEvening: julyEvening, skunk: skunk, bigWalleye: bigWalleye)
    }

    /// Stats as of July 20, 2026 at noon UTC.
    private func calculate(_ log: Log, range: StatsRange = .allTime, speciesID: String? = nil) throws -> StatsCalculator {
        try StatsCalculator(trips: log.trips, range: range, speciesID: speciesID, now: date(7, 20, 12), calendar: Self.calendar)
    }

    // MARK: Totals

    @Test func totalsCountEveryFishTripAndDay() throws {
        let stats = try calculate(makeLog())
        #expect(stats.totalFish == 6)
        #expect(stats.tripCount == 3)
        #expect(stats.daysFished == 3)
        #expect(stats.speciesCount == 2)
        #expect(stats.releasedFish == 2)
    }

    @Test func ratesUseHoursOnTheWater() throws {
        let stats = try calculate(makeLog())
        #expect(abs(stats.hoursFished - 6) < 0.0001)
        let perHour = try #require(stats.fishPerHour)
        #expect(abs(perHour - 1) < 0.0001)
        let skunkRate = try #require(stats.skunkRate)
        #expect(abs(skunkRate - 1.0 / 3.0) < 0.0001)
        let releasedShare = try #require(stats.releasedShare)
        #expect(abs(releasedShare - 2.0 / 6.0) < 0.0001)
    }

    @Test func runawayTripIsCappedAtSixteenHours() throws {
        let start = try date(7, 1, 6)
        let trip = makeTrip(from: start, to: nil, at: "Lake Simcoe")
        try context.save()
        let stats = StatsCalculator(trips: [trip], now: start.addingTimeInterval(30 * 3600), calendar: Self.calendar)
        #expect(stats.hoursFished == StatsLimits.maxTripHours)
    }

    @Test func unknownFishCountButAreNotASpecies() throws {
        let trip = try makeTrip(from: date(7, 1, 6), to: date(7, 1, 8), at: "Lake Simcoe")
        try add(FishCatch(speciesID: SpeciesCatalog.unknownID, timestamp: date(7, 1, 7), count: 2, lengthCm: 30), to: trip)
        try add(FishCatch(speciesID: "walleye", timestamp: date(7, 1, 7, 30)), to: trip)
        try context.save()
        let stats = try StatsCalculator(trips: [trip], now: date(7, 20, 12), calendar: Self.calendar)
        #expect(stats.totalFish == 3)
        #expect(stats.speciesCount == 1)
        #expect(stats.personalBests.map(\.speciesID) == ["walleye"])
    }

    @Test func catchWithoutATripIsIgnored() throws {
        let trip = try StatsTripRecord(startDate: date(7, 1, 6), endDate: date(7, 1, 8))
        let onTrip = try StatsCatchRecord(tripID: trip.id, timestamp: date(7, 1, 7), speciesID: "walleye")
        let loose = try StatsCatchRecord(tripID: nil, timestamp: date(7, 1, 7), speciesID: "walleye")
        let stats = try StatsCalculator(trips: [trip], catches: [onTrip, loose], now: date(7, 20, 12), calendar: Self.calendar)
        #expect(stats.totalFish == 1)
    }

    @Test func storeInputReadsTheSameLog() throws {
        _ = try makeLog()
        let input = StatsStore.input(in: context)
        #expect(input.trips.count == 3)
        #expect(input.catches.count == 3)
        let stats = try StatsCalculator(input: input, now: date(7, 20, 12), calendar: Self.calendar)
        #expect(stats.totalFish == 6)
        #expect(stats.tripCount == 3)
    }

    // MARK: Filters

    @Test func thisMonthOnlyCountsTripsStartedThisMonth() throws {
        let stats = try calculate(makeLog(), range: .thisMonth)
        #expect(stats.tripCount == 2)
        #expect(stats.totalFish == 1)
        #expect(stats.bySpecies.map(\.speciesID) == ["walleye"])
    }

    @Test func speciesFilterKeepsEveryTrip() throws {
        let stats = try calculate(makeLog(), speciesID: "walleye")
        #expect(stats.totalFish == 2)
        #expect(stats.tripCount == 3)
        #expect(abs(stats.hoursFished - 6) < 0.0001)
        let skunkRate = try #require(stats.skunkRate)
        #expect(abs(skunkRate - 1.0 / 3.0) < 0.0001)
    }

    // MARK: Breakdowns

    @Test func speciesAreRankedByFishCaught() throws {
        let stats = try calculate(makeLog())
        #expect(stats.bySpecies.map(\.speciesID) == ["yellow_perch", "walleye"])
        #expect(stats.bySpecies.map(\.count) == [4, 2])
    }

    @Test func fishLandInTheHourTheyWereLogged() throws {
        let stats = try calculate(makeLog())
        #expect(stats.byHourOfDay.count == 24)
        #expect(stats.byHourOfDay[7].count == 1)
        #expect(stats.byHourOfDay[8].count == 4)
        #expect(stats.byHourOfDay[19].count == 1)
        let total = stats.byHourOfDay.reduce(0) { $0 + $1.count }
        #expect(total == 6)
    }

    @Test func monthsCountTripsAndFish() throws {
        let stats = try calculate(makeLog())
        let juneStart = try date(6, 1, 0)
        let julyStart = try date(7, 1, 0)
        #expect(stats.byMonth.map(\.month) == [juneStart, julyStart])
        #expect(stats.byMonth.map(\.trips) == [1, 2])
        #expect(stats.byMonth.map(\.count) == [5, 1])
    }

    @Test func measuredLengthFillsInTheSizeClass() throws {
        // The perch were logged as small. The walleye were only measured; 55 and 62 cm are both
        // large on the walleye cutoffs.
        let stats = try calculate(makeLog())
        #expect(stats.sizeClassCounts.map(\.sizeClass) == SizeClass.allCases)
        #expect(stats.sizeClassCounts.map(\.count) == [0, 4, 0, 2, 0])
    }

    @Test func personalBestsComeFromMeasuredFish() throws {
        let log = try makeLog()
        let stats = try calculate(log)
        #expect(stats.personalBests.map(\.speciesID) == ["walleye", "yellow_perch"])
        let walleye = try #require(stats.personalBests.first)
        #expect(walleye.longestCm == 62)
        #expect(walleye.heaviestKg == 2.4)
        #expect(walleye.longestCatchID == log.bigWalleye.id)
        let perch = try #require(stats.personalBests.last)
        #expect(perch.longestCm == nil)
        #expect(perch.biggestClass == .small)
    }

    @Test func spotsRankByFishAndListTripsNewestFirst() throws {
        let log = try makeLog()
        let stats = try calculate(log)
        #expect(stats.topSpots.map(\.name) == ["Lake Simcoe", "Bass Pond"])
        let simcoe = try #require(stats.topSpots.first)
        #expect(simcoe.fish == 6)
        #expect(simcoe.trips == 2)
        #expect(simcoe.tripIDs == [log.julyEvening.id, log.june.id])
    }

    @Test func lureSpellingsFoldTogether() throws {
        let stats = try calculate(makeLog())
        #expect(stats.topLures.map(\.key) == ["jig", "crankbait"])
        let jig = try #require(stats.topLures.first)
        #expect(jig.fish == 5)
        #expect(jig.catches == 2)
        // Each spelling was used once, so the newer one is shown.
        #expect(jig.name == "jig")
    }

    @Test func trendRatesSkipTripsWithoutATrend() throws {
        let log = try makeLog()
        log.june.pressureTrend = .falling
        log.skunk.pressureTrend = .rising
        let rates = try calculate(log).ratesByPressureTrend()
        #expect(rates.map(\.label) == ["Rising", "Falling"])
        let falling = try #require(rates.last)
        #expect(falling.trips == 1)
        #expect(falling.fish == 5)
        #expect(abs(falling.fishPerHour - 5.0 / 3.0) < 0.0001)
    }
}
