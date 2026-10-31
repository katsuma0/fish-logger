import Foundation
import SwiftData
import Testing
@testable import FishLogger

/// Starting, ending, logging, and deleting through `CatchLogger`, in a throwaway store.
@MainActor
struct CatchLoggerTests {
    /// Held by the suite so it outlives every model a test touches.
    let container: ModelContainer
    var context: ModelContext { container.mainContext }

    init() {
        container = AppModelContainer.inMemory()
    }

    /// Rows of one model type in the store, saved or not.
    private func count<T: PersistentModel>(_ type: T.Type) throws -> Int {
        try context.fetchCount(FetchDescriptor<T>())
    }

    // MARK: Logging

    @Test func logCatchStartsATripWhenNoneIsRunning() throws {
        #expect(CatchLogger.activeTrip(in: context) == nil)
        let fishCatch = CatchLogger.logCatch(speciesID: "walleye", in: context)
        let trip = try #require(fishCatch.trip)
        #expect(trip.isActive)
        #expect(CatchLogger.activeTrip(in: context)?.id == trip.id)
        let trips = try count(Trip.self)
        #expect(trips == 1)
    }

    @Test func logCatchJoinsTheRunningTrip() throws {
        let trip = CatchLogger.startTrip(in: context, locationName: "Lake Simcoe")
        let fishCatch = CatchLogger.logCatch(speciesID: "walleye", in: context)
        #expect(fishCatch.trip?.id == trip.id)
        let trips = try count(Trip.self)
        #expect(trips == 1)
    }

    @Test func tripStartedByLoggingCopiesTheLastTripsWaterAndMethod() throws {
        let earlier = CatchLogger.startTrip(in: context, waterBody: .river, method: .kayak, at: Date(timeIntervalSinceNow: -7200))
        CatchLogger.endTrip(earlier, in: context, at: Date(timeIntervalSinceNow: -3600))
        let fishCatch = CatchLogger.logCatch(speciesID: "walleye", in: context)
        let trip = try #require(fishCatch.trip)
        #expect(trip.id != earlier.id)
        #expect(trip.waterBody == .river)
        #expect(trip.method == .kayak)
    }

    @Test func logAnotherCopiesSpeciesAndSize() throws {
        let first = CatchLogger.logCatch(speciesID: "yellow_perch", sizeClass: .small, in: context)
        first.lure = "Jig"
        first.released = false
        let second = CatchLogger.logAnother(like: first, in: context)
        #expect(second.id != first.id)
        #expect(second.speciesID == "yellow_perch")
        #expect(second.sizeClass == .small)
        #expect(second.lure == "Jig")
        #expect(second.released == false)
        let trip = try #require(first.trip)
        #expect(second.trip?.id == trip.id)
    }

    @Test func logAnotherKeepsACustomSpeciesName() {
        let first = CatchLogger.logCatch(speciesID: SpeciesCatalog.unknownID, in: context)
        first.customSpeciesName = "Tiger trout"
        let second = CatchLogger.logAnother(like: first, in: context)
        #expect(second.speciesID == SpeciesCatalog.unknownID)
        #expect(second.speciesName == "Tiger trout")
    }

    // MARK: Ending

    @Test func endTripSetsTheEndDate() {
        let start = Date(timeIntervalSinceNow: -3 * 3600)
        let end = Date(timeIntervalSinceNow: -600)
        let trip = CatchLogger.startTrip(in: context, at: start)
        CatchLogger.endTrip(trip, in: context, at: end)
        #expect(trip.endDate == end)
        #expect(!trip.isActive)
        #expect(CatchLogger.activeTrip(in: context) == nil)
    }

    @Test func endTripNeverEndsBeforeTheStart() {
        let start = Date(timeIntervalSinceNow: -3600)
        let trip = CatchLogger.startTrip(in: context, at: start)
        CatchLogger.endTrip(trip, in: context, at: start.addingTimeInterval(-600))
        #expect(trip.endDate == start)
    }

    // MARK: Deleting

    @Test func deleteAllRemovesTripsAndTheirCatches() throws {
        let morning = CatchLogger.startTrip(in: context, at: Date(timeIntervalSinceNow: -5 * 3600))
        CatchLogger.logCatch(speciesID: "walleye", to: morning, in: context)
        CatchLogger.logCatch(speciesID: "yellow_perch", count: 3, to: morning, in: context)
        CatchLogger.endTrip(morning, in: context, at: Date(timeIntervalSinceNow: -4 * 3600))
        let evening = CatchLogger.startTrip(in: context)
        CatchLogger.logCatch(speciesID: "walleye", to: evening, in: context)
        let catchesBefore = try count(FishCatch.self)
        try #require(catchesBefore == 3)

        CatchLogger.deleteAll([morning, evening], in: context)

        let trips = try count(Trip.self)
        let catches = try count(FishCatch.self)
        #expect(trips == 0)
        #expect(catches == 0)
    }

    @Test func deleteAllRemovesPhotosToo() throws {
        let trip = CatchLogger.startTrip(in: context)
        let fishCatch = CatchLogger.logCatch(speciesID: "walleye", to: trip, in: context)
        let photo = CatchPhoto(imageData: Data([0xFF, 0xD8, 0xFF]), thumbnailData: nil)
        context.insert(photo)
        photo.fishCatch = fishCatch
        try context.save()

        CatchLogger.deleteAll([trip], in: context)

        let photos = try count(CatchPhoto.self)
        #expect(photos == 0)
    }

    @Test func deleteAllLeavesOtherTripsAlone() throws {
        let old = CatchLogger.startTrip(in: context, at: Date(timeIntervalSinceNow: -7200))
        CatchLogger.logCatch(speciesID: "walleye", to: old, in: context)
        CatchLogger.endTrip(old, in: context, at: Date(timeIntervalSinceNow: -3600))
        let kept = CatchLogger.startTrip(in: context)
        CatchLogger.logCatch(speciesID: "yellow_perch", to: kept, in: context)

        CatchLogger.deleteAll([old], in: context)

        let trips = try context.fetch(FetchDescriptor<Trip>())
        #expect(trips.map(\.id) == [kept.id])
        let catches = try context.fetch(FetchDescriptor<FishCatch>())
        #expect(catches.map(\.speciesID) == ["yellow_perch"])
    }
}
