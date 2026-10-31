import Foundation
import SwiftData

/// A trip copied out of SwiftData with only what Stats reads, so the numbers can be worked out
/// off the main thread without touching a model.
struct StatsTripRecord: Sendable {
    let id: UUID
    let startDate: Date
    let endDate: Date?
    /// The trip's display name, so blank names group as "Unnamed spot".
    let spotName: String
    let pressureHPa: Double?
    let pressureTrend: PressureTrend?
    let moonPhase: Double?
    let weather: WeatherCondition?

    init(
        id: UUID = UUID(),
        startDate: Date,
        endDate: Date? = nil,
        spotName: String = "Unnamed spot",
        pressureHPa: Double? = nil,
        pressureTrend: PressureTrend? = nil,
        moonPhase: Double? = nil,
        weather: WeatherCondition? = nil
    ) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.spotName = spotName
        self.pressureHPa = pressureHPa
        self.pressureTrend = pressureTrend
        self.moonPhase = moonPhase
        self.weather = weather
    }

    /// Reads the model, so call it on the thread that owns the trip's context. Stats makes the
    /// copy on a background context of its own, tests make it on the main one.
    init(_ trip: Trip) {
        self.init(
            id: trip.id,
            startDate: trip.startDate,
            endDate: trip.endDate,
            spotName: trip.displayName,
            pressureHPa: trip.pressureHPa,
            pressureTrend: trip.pressureTrend,
            moonPhase: trip.moonPhase,
            weather: trip.weather
        )
    }
}

/// A catch copied out of SwiftData with only what Stats reads.
struct StatsCatchRecord: Sendable {
    let id: UUID
    /// Nil for a catch with no trip. Those never count toward stats.
    let tripID: UUID?
    let timestamp: Date
    let speciesID: String
    let count: Int
    let lengthCm: Double?
    let weightKg: Double?
    /// The class picked when logging, or one worked out from the measured length.
    let sizeClass: SizeClass?
    let released: Bool
    let lure: String

    init(
        id: UUID = UUID(),
        tripID: UUID?,
        timestamp: Date,
        speciesID: String,
        count: Int = 1,
        lengthCm: Double? = nil,
        weightKg: Double? = nil,
        sizeClass: SizeClass? = nil,
        released: Bool = true,
        lure: String = ""
    ) {
        self.id = id
        self.tripID = tripID
        self.timestamp = timestamp
        self.speciesID = speciesID
        self.count = count
        self.lengthCm = lengthCm
        self.weightKg = weightKg
        self.sizeClass = sizeClass
        self.released = released
        self.lure = lure
    }

    /// Reads the model, so call it on the thread that owns the catch's context. `tripID` is
    /// passed in because the caller already knows it, which saves a relationship read per catch.
    init(_ fishCatch: FishCatch, tripID: UUID?) {
        self.init(
            id: fishCatch.id,
            tripID: tripID,
            timestamp: fishCatch.timestamp,
            speciesID: fishCatch.speciesID,
            count: fishCatch.count,
            lengthCm: fishCatch.lengthCm,
            weightKg: fishCatch.weightKg,
            sizeClass: fishCatch.effectiveSizeClass,
            released: fishCatch.released,
            lure: fishCatch.lure
        )
    }
}

/// Everything the calculator reads: the whole log as plain values.
struct StatsInput: Sendable {
    var trips: [StatsTripRecord]
    var catches: [StatsCatchRecord]

    init(trips: [StatsTripRecord], catches: [StatsCatchRecord]) {
        self.trips = trips
        self.catches = catches
    }

    /// Copies these trips and their catches. For tests and previews that already hold models.
    @MainActor
    init(trips models: [Trip]) {
        var trips: [StatsTripRecord] = []
        var catches: [StatsCatchRecord] = []
        trips.reserveCapacity(models.count)
        for trip in models where !trip.isDeleted {
            trips.append(StatsTripRecord(trip))
            for fishCatch in trip.catches where !fishCatch.isDeleted {
                catches.append(StatsCatchRecord(fishCatch, tripID: trip.id))
            }
        }
        self.init(trips: trips, catches: catches)
    }
}

/// Cheap fingerprint of the log. The Stats screen recomputes only when this changes, so a
/// render, a tab switch, or a keystroke somewhere else never walks every catch.
struct StatsDataVersion: Hashable {
    var trips: Int
    var catches: Int
    var newestCatch: Date?
    /// Bumped after a save, so an edit that changes no count (a length, a lure) still shows up.
    var edits: Int
}

/// The fetches behind the Stats screen. The cheap ones run on the main actor with the view's
/// context. The full copy is nonisolated so Stats can run it off the main thread.
@MainActor
enum StatsStore {
    /// Two counts and one single-row fetch. Fast enough to run on every save.
    static func dataVersion(in context: ModelContext, edits: Int) -> StatsDataVersion {
        let trips = (try? context.fetchCount(FetchDescriptor<Trip>())) ?? 0
        let catches = (try? context.fetchCount(FetchDescriptor<FishCatch>())) ?? 0
        var newest = FetchDescriptor<FishCatch>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
        newest.fetchLimit = 1
        newest.propertiesToFetch = [\.timestamp]
        let newestCatch = (try? context.fetch(newest))?.first?.timestamp
        return StatsDataVersion(trips: trips, catches: catches, newestCatch: newestCatch, edits: edits)
    }

    /// The whole log as plain values: one fetch for trips, one for catches. Catches are matched
    /// to trips by identity rather than through `trip.catches`, which would fault once per trip.
    /// Stats reads most fields of both, so these are full fetches. Only runs when the data
    /// version changes, never per render.
    ///
    /// Nonisolated because a long log means thousands of model reads. Stats calls it inside a
    /// detached task on a context made there, so none of that lands on the main thread. Call it
    /// on the thread that owns `context`.
    nonisolated static func input(in context: ModelContext) -> StatsInput {
        let tripModels = (try? context.fetch(FetchDescriptor<Trip>())) ?? []
        let catchModels = (try? context.fetch(FetchDescriptor<FishCatch>())) ?? []

        var trips: [StatsTripRecord] = []
        trips.reserveCapacity(tripModels.count)
        var tripIDs: [PersistentIdentifier: UUID] = [:]
        tripIDs.reserveCapacity(tripModels.count)
        for trip in tripModels where !trip.isDeleted {
            trips.append(StatsTripRecord(trip))
            tripIDs[trip.persistentModelID] = trip.id
        }

        var catches: [StatsCatchRecord] = []
        catches.reserveCapacity(catchModels.count)
        for fishCatch in catchModels where !fishCatch.isDeleted {
            guard let trip = fishCatch.trip, let tripID = tripIDs[trip.persistentModelID] else { continue }
            catches.append(StatsCatchRecord(fishCatch, tripID: tripID))
        }
        return StatsInput(trips: trips, catches: catches)
    }

    /// One catch by its id, or nil when it has been deleted since the stats were worked out.
    static func fishCatch(id catchID: UUID, in context: ModelContext) -> FishCatch? {
        let wanted = catchID
        var descriptor = FetchDescriptor<FishCatch>(predicate: #Predicate<FishCatch> { $0.id == wanted })
        descriptor.fetchLimit = 1
        guard let fishCatch = (try? context.fetch(descriptor))?.first, !fishCatch.isDeleted else { return nil }
        return fishCatch
    }
}

/// What the Stats screen shows for one range and species filter. Built off the main thread from
/// a `StatsInput`, then handed to the view in one assignment.
struct StatsSnapshot: Sendable {
    let stats: StatsCalculator
    /// Condition charts with enough trips to mean something, in screen order.
    let conditionGroups: [StatsConditionGroup]
    /// Titles of the condition charts left out for having too few trips.
    let hiddenConditionTitles: [String]
    /// Every species in the whole log, by name, for the filter menu. Ignores the filters.
    let loggedSpeciesIDs: [String]
    /// Trips in the whole log, ignoring the filters.
    let totalTripCount: Int

    init(
        input: StatsInput,
        range: StatsRange,
        speciesID: String?,
        pressureUnit: PressureUnit?,
        now: Date = .now,
        calendar: Calendar = .current
    ) {
        let stats = StatsCalculator(input: input, range: range, speciesID: speciesID, now: now, calendar: calendar)
        let groups = stats.conditionGroups(pressureUnit: pressureUnit)
        self.stats = stats
        self.conditionGroups = groups.filter(\.hasEnoughTrips)
        self.hiddenConditionTitles = groups.filter { !$0.hasEnoughTrips }.map(\.title)
        self.loggedSpeciesIDs = StatsCalculator.loggedSpeciesIDs(in: input.catches)
        self.totalTripCount = input.trips.count
    }
}
