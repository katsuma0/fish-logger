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

    /// Logs a fish in one call. Attaches to the active trip, or starts one if there is none,
    /// so a catch is never lost because nobody pressed Start.
    @discardableResult
    static func logCatch(
        speciesID: String,
        count: Int = 1,
        sizeClass: SizeClass? = nil,
        lengthCm: Double? = nil,
        weightKg: Double? = nil,
        photo: UIImage? = nil,
        identifiedBy: IdentificationSource? = nil,
        in context: ModelContext,
        at date: Date = .now
    ) -> FishCatch {
        let trip = activeTrip(in: context) ?? startTrip(in: context, at: date)
        let fishCatch = FishCatch(
            speciesID: speciesID,
            timestamp: date,
            count: count,
            sizeClass: sizeClass,
            lengthCm: lengthCm,
            weightKg: weightKg
        )
        fishCatch.identifiedBy = identifiedBy

        let settings = AppSettings.shared
        let location = LocationService.shared.recentLocation()
        if settings.tagCatchLocation, let location {
            fishCatch.latitude = location.coordinate.latitude
            fishCatch.longitude = location.coordinate.longitude
        }
        if settings.useBarometer {
            fishCatch.pressureHPa = BarometerService.shared.seaLevelPressureHPa(
                altitudeM: location?.altitude,
                airTempC: trip.airTempC
            )
        }
        fishCatch.waterTempC = trip.waterTempC

        // Insert before linking; SwiftData is happiest when both ends already live in the context.
        context.insert(fishCatch)
        fishCatch.trip = trip
        if let photo, let catchPhoto = CatchPhoto(image: photo) {
            context.insert(catchPhoto)
            catchPhoto.fishCatch = fishCatch
        }
        save(context)
        return fishCatch
    }

    /// Same species and size as an earlier entry, logged now. For "another one".
    @discardableResult
    static func logAnother(like existing: FishCatch, in context: ModelContext) -> FishCatch {
        let fishCatch = logCatch(speciesID: existing.speciesID, sizeClass: existing.sizeClass, in: context)
        fishCatch.customSpeciesName = existing.customSpeciesName
        fishCatch.lure = existing.lure
        fishCatch.released = existing.released
        save(context)
        return fishCatch
    }

    static func addPhoto(_ image: UIImage, to fishCatch: FishCatch, in context: ModelContext) {
        guard let catchPhoto = CatchPhoto(image: image) else { return }
        context.insert(catchPhoto)
        catchPhoto.fishCatch = fishCatch
        save(context)
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

    /// Species logged most often, all time. Feeds the quick log grid after favourites.
    static func mostLoggedSpeciesIDs(in context: ModelContext, limit: Int = 12) -> [String] {
        let catches = (try? context.fetch(FetchDescriptor<FishCatch>())) ?? []
        var tally: [String: Int] = [:]
        for fishCatch in catches where fishCatch.speciesID != SpeciesCatalog.unknownID {
            tally[fishCatch.speciesID, default: 0] += fishCatch.count
        }
        return tally
            .sorted { $0.value == $1.value ? $0.key < $1.key : $0.value > $1.value }
            .prefix(limit)
            .map(\.key)
    }

    /// Previous spots with coordinates, newest first, one per name.
    static func savedSpots(in context: ModelContext) -> [(name: String, latitude: Double?, longitude: Double?)] {
        let descriptor = FetchDescriptor<Trip>(sortBy: [SortDescriptor(\.startDate, order: .reverse)])
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
        savedSpots(in: context)
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
}

/// Fills in a trip's conditions in the background: GPS fix, spot name, barometer, moon, sun,
/// and weather when online. Each step fails quietly, because offline is normal on the water.
@MainActor
enum TripConditionsUpdater {
    /// - Parameter forceWeather: refetch weather even if the trip already has some, and overwrite it.
    static func refresh(_ trip: Trip, in context: ModelContext, forceWeather: Bool = false) async {
        let settings = AppSettings.shared

        if trip.latitude == nil || trip.longitude == nil, trip.isActive {
            if let location = await LocationService.shared.currentLocation() {
                trip.latitude = location.coordinate.latitude
                trip.longitude = location.coordinate.longitude
            }
        }

        if let latitude = trip.latitude, let longitude = trip.longitude {
            let location = CLLocation(latitude: latitude, longitude: longitude)
            if trip.locationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                if let saved = CatchLogger.nearbySpotName(to: location, in: context) {
                    trip.locationName = saved
                } else if let name = await LocationService.shared.placeName(for: location) {
                    trip.locationName = name
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

        if settings.useBarometer, trip.isActive, trip.pressureHPa == nil,
           let station = await BarometerService.shared.readOnce() {
            let altitude = LocationService.shared.recentLocation()?.altitude ?? 0
            trip.pressureHPa = BarometerService.seaLevel(stationHPa: station, altitudeM: altitude, airTempC: trip.airTempC ?? 15)
        }

        let wantsWeather = forceWeather || (settings.autoFetchWeather && trip.weatherFetchedAt == nil)
        if wantsWeather, let latitude = trip.latitude, let longitude = trip.longitude {
            if let snapshot = try? await WeatherService.fetch(latitude: latitude, longitude: longitude, at: trip.startDate) {
                WeatherService.apply(snapshot, to: trip, overwrite: forceWeather)
            }
        }

        CatchLogger.save(context)
    }
}
