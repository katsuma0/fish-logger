import CoreLocation
import Foundation
import SwiftData
import UIKit

/// Every write that starts trips, ends trips, or logs fish goes through here, so the Today screen,
/// photo ID, and Siri all behave the same way.
@MainActor
enum CatchLogger {
    /// The trip with no end date, newest first if somehow there are several.
    static func activeTrip(in context: ModelContext) -> Trip? {
        var descriptor = FetchDescriptor<Trip>(
            predicate: #Predicate<Trip> { $0.endDate == nil },
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return (try? context.fetch(descriptor))?.first
    }

    /// The newest trip, finished or not.
    static func latestTrip(in context: ModelContext) -> Trip? {
        var descriptor = FetchDescriptor<Trip>(sortBy: [SortDescriptor(\.startDate, order: .reverse)])
        descriptor.fetchLimit = 1
        return (try? context.fetch(descriptor))?.first
    }

    // MARK: Forgotten trips

    /// No fish, no start, and no Keep going for this long, and an open trip was almost certainly
    /// left running. Same quiet stretch the Today screen asks about.
    static let forgottenTripInterval: TimeInterval = 8 * 60 * 60

    /// True for an open trip quiet for 8 hours. Only the quiet test lives here: Today also asks about
    /// a trip from an earlier day, but nothing here can ask, and splitting at midnight would break an
    /// overnight session in two.
    static func isForgotten(_ trip: Trip, now: Date = .now) -> Bool {
        guard trip.isActive else { return false }
        var lastActivity = max(lastCatchDate(in: trip) ?? trip.startDate, trip.startDate)
        if let keptGoing = AppSettings.shared.keptGoingDate(forTripID: trip.id) {
            lastActivity = max(lastActivity, keptGoing)
        }
        return now.timeIntervalSince(lastActivity) > forgottenTripInterval
    }

    /// The open trip a new fish joins, or nil when logging would start a trip: none is running, or
    /// the open one looks forgotten. Use this, not `activeTrip`, to word a Log button or to tell
    /// whether logging is about to start a trip.
    static func currentTrip(in context: ModelContext, now: Date = .now) -> Trip? {
        guard let trip = activeTrip(in: context), !isForgotten(trip, now: now) else { return nil }
        return trip
    }

    /// Where a forgotten trip ends: at its last fish, or at its start when it has none.
    static func forgottenTripEndDate(for trip: Trip) -> Date {
        lastCatchDate(in: trip) ?? trip.startDate
    }

    static func lastCatchDate(in trip: Trip) -> Date? {
        trip.catches.map(\.timestamp).max()
    }

    /// Starts a trip right away with whatever is known. Call `TripConditionsUpdater.refresh`
    /// afterwards to fill in GPS, weather, pressure, moon, and sun without blocking the tap.
    @discardableResult
    static func startTrip(
        in context: ModelContext,
        locationName: String = "",
        waterBody: WaterBodyType = .lake,
        method: FishingMethod = .shore,
        at date: Date = .now
    ) -> Trip {
        // The first trip is when location matters, so ask then rather than at launch. Does nothing
        // once the person has answered.
        LocationService.shared.requestPermission()
        for trip in openTrips(in: context) { trip.endDate = date }

        let trip = Trip(startDate: date, locationName: locationName, waterBody: waterBody, method: method)
        if let location = LocationService.shared.recentLocation() {
            trip.latitude = location.coordinate.latitude
            trip.longitude = location.coordinate.longitude
        }
        let moon = Astronomy.moon(on: date)
        trip.moonPhase = moon.phase
        if let latitude = trip.latitude, let longitude = trip.longitude {
            let sun = Astronomy.sunTimes(on: date, latitude: latitude, longitude: longitude)
            trip.sunrise = sun.sunrise
            trip.sunset = sun.sunset
        }
        context.insert(trip)
        save(context)
        startSensors()
        return trip
    }

    static func endTrip(_ trip: Trip, in context: ModelContext, at date: Date = .now) {
        trip.endDate = max(date, trip.startDate)
        save(context)
        stopSensors()
    }

    /// Logs a fish in one call. Attaches to `trip` when given (adding to a past trip), otherwise to the
    /// active trip, starting one if needed so a catch is never lost because nobody pressed Start.
    /// A photo is encoded in the background and attached when ready, so the tap never waits on it.
    @discardableResult
    static func logCatch(
        speciesID: String,
        count: Int = 1,
        sizeClass: SizeClass? = nil,
        lengthCm: Double? = nil,
        weightKg: Double? = nil,
        photo: UIImage? = nil,
        identifiedBy: IdentificationSource? = nil,
        to targetTrip: Trip? = nil,
        in context: ModelContext,
        at date: Date = .now
    ) -> FishCatch {
        let fishCatch = insertCatch(
            speciesID: speciesID,
            count: count,
            sizeClass: sizeClass,
            lengthCm: lengthCm,
            weightKg: weightKg,
            identifiedBy: identifiedBy,
            to: targetTrip,
            in: context,
            at: date
        )
        save(context)
        if let photo {
            Task { await attachPhoto(photo, to: fishCatch, in: context) }
        }
        return fishCatch
    }

    /// Same species and size as an earlier entry, logged now. For "another one". Saves once.
    @discardableResult
    static func logAnother(like existing: FishCatch, in context: ModelContext) -> FishCatch {
        let fishCatch = insertCatch(speciesID: existing.speciesID, sizeClass: existing.sizeClass, in: context)
        fishCatch.customSpeciesName = existing.customSpeciesName
        fishCatch.lure = existing.lure
        fishCatch.released = existing.released
        save(context)
        return fishCatch
    }

    /// Encodes on the calling thread. Prefer `attachPhoto`, which keeps the main thread free.
    static func addPhoto(_ image: UIImage, to fishCatch: FishCatch, in context: ModelContext) {
        guard let catchPhoto = CatchPhoto(image: image) else { return }
        context.insert(catchPhoto)
        catchPhoto.fishCatch = fishCatch
        save(context)
    }

    /// Encodes the photo off the main thread, then attaches it. Safe to call from a button action
    /// inside `Task { }`. Skips quietly if the catch was deleted while the photo was encoding.
    static func attachPhoto(_ image: UIImage, to fishCatch: FishCatch, in context: ModelContext) async {
        // Taken before the wait so several photos keep the order they were added in.
        let createdAt = Date.now
        let encoded = await PhotoEncoder.shared.encode(image)
        insert(encoded, createdAt: createdAt, to: fishCatch, in: context)
    }

    /// Same as `attachPhoto(_:to:in:)` for photo library file data. Cheaper than decoding a
    /// `UIImage` first, because ImageIO downsamples while it decodes.
    static func attachPhoto(data: Data, to fishCatch: FishCatch, in context: ModelContext) async {
        let createdAt = Date.now
        let encoded = await PhotoEncoder.shared.encode(fileData: data)
        insert(encoded, createdAt: createdAt, to: fishCatch, in: context)
    }

    static func delete(_ fishCatch: FishCatch, in context: ModelContext) {
        context.delete(fishCatch)
        save(context)
    }

    static func delete(_ trip: Trip, in context: ModelContext) {
        if trip.isActive { stopSensors() }
        context.delete(trip)
        save(context)
    }

    /// Deletes trips with their catches and photos, then saves once.
    static func deleteAll(_ trips: [Trip], in context: ModelContext) {
        guard !trips.isEmpty else { return }
        if trips.contains(where: \.isActive) { stopSensors() }
        for trip in trips {
            // Explicit rather than trusting the cascade, so nothing is left behind if a
            // relationship was never loaded.
            for fishCatch in trip.catches {
                for photo in fishCatch.photos { context.delete(photo) }
                context.delete(fishCatch)
            }
            context.delete(trip)
        }
        save(context)
    }

    /// Species logged most often, all time. Feeds the quick log grid after favourites.
    static func mostLoggedSpeciesIDs(in context: ModelContext, limit: Int = 12) -> [String] {
        let unknownID = SpeciesCatalog.unknownID
        var descriptor = FetchDescriptor<FishCatch>(predicate: #Predicate<FishCatch> { $0.speciesID != unknownID })
        // Two fields per catch, so a long history does not pull notes and conditions into memory.
        descriptor.propertiesToFetch = [\.speciesID, \.count]
        let catches = (try? context.fetch(descriptor)) ?? []
        var tally: [String: Int] = [:]
        for fishCatch in catches {
            tally[fishCatch.speciesID, default: 0] += fishCatch.count
        }
        return tally
            .sorted { $0.value == $1.value ? $0.key < $1.key : $0.value > $1.value }
            .prefix(limit)
            .map(\.key)
    }

    /// Previous spots with coordinates, newest first, one per name.
    static func savedSpots(in context: ModelContext) -> [(name: String, latitude: Double?, longitude: Double?)] {
        var descriptor = FetchDescriptor<Trip>(sortBy: [SortDescriptor(\.startDate, order: .reverse)])
        descriptor.propertiesToFetch = [\.locationName, \.latitude, \.longitude, \.startDate]
        let trips = (try? context.fetch(descriptor)) ?? []
        var seen = Set<String>()
        var spots: [(name: String, latitude: Double?, longitude: Double?)] = []
        for trip in trips {
            let name = trip.locationName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty, seen.insert(name.lowercased()).inserted else { continue }
            spots.append((name: name, latitude: trip.latitude, longitude: trip.longitude))
        }
        return spots
    }

    /// Name of a saved spot within `radius` metres of the location, closest first.
    static func nearbySpotName(to location: CLLocation, in context: ModelContext, radius: CLLocationDistance = 750) -> String? {
        nearbySpotName(to: location, among: savedSpots(in: context), radius: radius)
    }

    /// Same match as `nearbySpotName(to:in:radius:)` but over spots already fetched.
    static func nearbySpotName(
        to location: CLLocation,
        among spots: [(name: String, latitude: Double?, longitude: Double?)],
        radius: CLLocationDistance = 750
    ) -> String? {
        spots
            .compactMap { spot -> (String, CLLocationDistance)? in
                guard let latitude = spot.latitude, let longitude = spot.longitude else { return nil }
                let distance = location.distance(from: CLLocation(latitude: latitude, longitude: longitude))
                return distance <= radius ? (spot.name, distance) : nil
            }
            .min { $0.1 < $1.1 }?
            .0
    }

    static func save(_ context: ModelContext) {
        do {
            try context.save()
        } catch {
            assertionFailure("Save failed: \(error)")
        }
    }

    /// GPS and barometer run only during a trip, to save battery.
    static func startSensors() {
        LocationService.shared.startTracking()
        if AppSettings.shared.useBarometer { BarometerService.shared.start() }
    }

    static func stopSensors() {
        LocationService.shared.stopTracking()
        BarometerService.shared.stop()
    }

    private static func openTrips(in context: ModelContext) -> [Trip] {
        let descriptor = FetchDescriptor<Trip>(predicate: #Predicate<Trip> { $0.endDate == nil })
        return (try? context.fetch(descriptor)) ?? []
    }

    /// Builds and inserts a catch without saving, so callers that set more fields save once.
    private static func insertCatch(
        speciesID: String,
        count: Int = 1,
        sizeClass: SizeClass? = nil,
        lengthCm: Double? = nil,
        weightKg: Double? = nil,
        identifiedBy: IdentificationSource? = nil,
        to targetTrip: Trip? = nil,
        in context: ModelContext,
        at date: Date = .now
    ) -> FishCatch {
        let trip = targetTrip ?? tripForNewCatch(in: context, at: date) ?? startTripLikeLast(in: context, at: date)
        // A catch added to a finished trip goes at its end, not at today's date.
        let timestamp = trip.endDate.map { min(date, $0) } ?? date
        let fishCatch = FishCatch(
            speciesID: speciesID,
            timestamp: timestamp,
            count: count,
            sizeClass: sizeClass,
            lengthCm: lengthCm,
            weightKg: weightKg
        )
        fishCatch.identifiedBy = identifiedBy

        let settings = AppSettings.shared
        let location = trip.isActive ? LocationService.shared.recentLocation() : nil
        if settings.tagCatchLocation, let location {
            fishCatch.latitude = location.coordinate.latitude
            fishCatch.longitude = location.coordinate.longitude
        }
        if settings.useBarometer, trip.isActive {
            fishCatch.pressureHPa = BarometerService.shared.seaLevelPressureHPa(
                altitudeM: location?.altitude,
                airTempC: trip.airTempC
            )
        }
        fishCatch.waterTempC = trip.waterTempC

        // Insert before linking; SwiftData is happiest when both ends already live in the context.
        context.insert(fishCatch)
        fishCatch.trip = trip
        return fishCatch
    }

    /// The open trip a fish logged with no trip given joins. A forgotten one is ended at its last fish
    /// first, so the new fish starts a new trip, as the Today screen promises. Ending it here rather
    /// than in `startTrip` matters: that would end it now and stretch it over days.
    private static func tripForNewCatch(in context: ModelContext, at date: Date) -> Trip? {
        guard let trip = activeTrip(in: context) else { return nil }
        guard isForgotten(trip, now: date) else { return trip }
        endTrip(trip, in: context, at: forgottenTripEndDate(for: trip))
        return nil
    }

    /// A trip started by logging a fish copies the water and method of the last trip, because most
    /// people fish the same way most days. The spot name fills in from GPS.
    private static func startTripLikeLast(in context: ModelContext, at date: Date) -> Trip {
        let last = latestTrip(in: context)
        return startTrip(
            in: context,
            waterBody: last?.waterBody ?? .lake,
            method: last?.method ?? .shore,
            at: date
        )
    }

    private static func insert(_ encoded: EncodedPhoto?, createdAt: Date, to fishCatch: FishCatch, in context: ModelContext) {
        // Undo or a delete may have removed the catch while the photo was encoding. A photo linked
        // to a deleted catch would make the save fail. Same check as the catch editor uses.
        guard let encoded, !fishCatch.isDeleted, fishCatch.modelContext != nil else { return }
        let catchPhoto = CatchPhoto(encoded, createdAt: createdAt)
        context.insert(catchPhoto)
        catchPhoto.fishCatch = fishCatch
        save(context)
    }
}

/// Fills in a trip's conditions in the background: GPS fix, spot name, barometer, moon, sun,
/// and weather when online. Each step fails quietly, because offline is normal on the water.
@MainActor
enum TripConditionsUpdater {
    /// - Parameter forceWeather: refetch weather even if the trip already has some, and overwrite it.
    static func refresh(_ trip: Trip, in context: ModelContext, forceWeather: Bool = false) async {
        let settings = AppSettings.shared

        if trip.latitude == nil || trip.longitude == nil, trip.isActive {
            // Check after every wait, even one that came back empty: Undo can delete the trip meanwhile.
            let location = await LocationService.shared.currentLocation()
            guard isLive(trip) else { return }
            if let location {
                trip.latitude = location.coordinate.latitude
                trip.longitude = location.coordinate.longitude
            }
        }

        if let latitude = trip.latitude, let longitude = trip.longitude {
            let location = CLLocation(latitude: latitude, longitude: longitude)
            if trip.locationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                if let saved = CatchLogger.nearbySpotName(to: location, in: context) {
                    trip.locationName = saved
                } else {
                    let name = await LocationService.shared.placeName(for: location)
                    guard isLive(trip) else { return }
                    // The person may have typed a name while the geocoder was working.
                    if let name, trip.locationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        trip.locationName = name
                    }
                }
            }
            if trip.sunrise == nil || trip.sunset == nil {
                let sun = Astronomy.sunTimes(on: trip.startDate, latitude: latitude, longitude: longitude)
                trip.sunrise = sun.sunrise
                trip.sunset = sun.sunset
            }
        }

        if trip.moonPhase == nil {
            trip.moonPhase = Astronomy.moon(on: trip.startDate).phase
        }

        if settings.useBarometer, trip.isActive, trip.pressureHPa == nil {
            let reading = await BarometerService.shared.readOnce()
            guard isLive(trip) else { return }
            if let station = reading {
                let altitude = LocationService.shared.recentLocation()?.altitude ?? 0
                trip.pressureHPa = BarometerService.seaLevel(stationHPa: station, altitudeM: altitude, airTempC: trip.airTempC ?? 15)
            }
        }

        let wantsWeather = forceWeather || (settings.autoFetchWeather && trip.weatherFetchedAt == nil)
        if wantsWeather, let latitude = trip.latitude, let longitude = trip.longitude {
            let snapshot = try? await WeatherService.fetch(latitude: latitude, longitude: longitude, at: trip.startDate)
            guard isLive(trip) else { return }
            if let snapshot {
                WeatherService.apply(snapshot, to: trip, overwrite: forceWeather)
            }
        }

        guard isLive(trip) else { return }
        CatchLogger.save(context)
    }

    /// False once the trip was deleted during one of the waits above. Writing to it then would fail.
    private static func isLive(_ trip: Trip) -> Bool {
        !trip.isDeleted && trip.modelContext != nil
    }
}
