import CoreLocation
import Foundation
import SwiftData

/// Time windows offered in the Log filter menu.
enum HistoryTimeFilter: String, CaseIterable, Identifiable {
    case allTime, thisMonth, last30Days, thisYear

    var id: String { rawValue }

    var label: String {
        switch self {
        case .allTime: "All time"
        case .thisMonth: "This month"
        case .last30Days: "Last 30 days"
        case .thisYear: "This year"
        }
    }

    func includes(_ date: Date, now: Date = .now, calendar: Calendar = .current) -> Bool {
        switch self {
        case .allTime:
            return true
        case .thisMonth:
            return calendar.isDate(date, equalTo: now, toGranularity: .month)
        case .last30Days:
            // Today plus the 29 days before it, counted in whole days so a morning trip a month ago does not flicker in and out.
            let today = calendar.startOfDay(for: now)
            guard let start = calendar.date(byAdding: .day, value: -29, to: today) else { return true }
            return date >= start
        case .thisYear:
            return calendar.isDate(date, equalTo: now, toGranularity: .year)
        }
    }
}

/// Trips that started on one calendar day, newest first.
struct HistoryDayGroup: Identifiable {
    let day: Date
    var trips: [Trip]

    var id: Date { day }

    var totalFish: Int { trips.reduce(0) { $0 + $1.totalFish } }

    /// "Sat, Oct 26", with the year added for earlier years.
    var title: String {
        if Calendar.current.isDate(day, equalTo: .now, toGranularity: .year) {
            return day.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
        }
        return day.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day().year())
    }
}

/// One species and how many of it, ready for ForEach.
struct HistorySpeciesCount: Identifiable {
    let speciesID: String
    let count: Int

    var id: String { speciesID }
    var species: Species? { SpeciesCatalog.species(id: speciesID) }
    var name: String { species?.commonName ?? "Unknown fish" }
}

/// A point on one of the Log maps: either a geotagged catch or a trip spot.
struct HistoryMapPin: Identifiable {
    let id: UUID
    let coordinate: CLLocationCoordinate2D
    let title: String
    let spokenLabel: String
    let species: Species?
    let trip: Trip?
}

@MainActor
enum HistoryTripFilter {
    static func apply(
        _ trips: [Trip],
        search: String,
        speciesID: String?,
        time: HistoryTimeFilter,
        now: Date = .now
    ) -> [Trip] {
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines)
        return trips.filter { trip in
            guard time.includes(trip.startDate, now: now) else { return false }
            if let speciesID, !trip.catches.contains(where: { $0.speciesID == speciesID }) {
                return false
            }
            if query.isEmpty { return true }
            return trip.historyMatches(query)
        }
    }

    /// Expects trips newest first, which is how the Log queries them, so each day is one contiguous run.
    static func groupedByDay(_ trips: [Trip]) -> [HistoryDayGroup] {
        let calendar = Calendar.current
        var groups: [HistoryDayGroup] = []
        for trip in trips {
            let day = calendar.startOfDay(for: trip.startDate)
            if let last = groups.last, last.day == day {
                groups[groups.count - 1].trips.append(trip)
            } else {
                groups.append(HistoryDayGroup(day: day, trips: [trip]))
            }
        }
        return groups
    }

    /// Species that appear anywhere in the log, by name. Only these are worth offering as filters.
    static func loggedSpecies(in trips: [Trip]) -> [Species] {
        var ids = Set<String>()
        for trip in trips {
            for fishCatch in trip.catches {
                ids.insert(fishCatch.speciesID)
            }
        }
        return ids
            .compactMap { SpeciesCatalog.species(id: $0) }
            .sorted { $0.commonName < $1.commonName }
    }
}

@MainActor
enum HistoryMapPins {
    /// Catches with a location, optionally only one species.
    static func catchPins(for trips: [Trip], speciesID: String?) -> [HistoryMapPin] {
        var pins: [HistoryMapPin] = []
        for trip in trips {
            for fishCatch in trip.catches {
                if let speciesID, fishCatch.speciesID != speciesID { continue }
                guard let coordinate = fishCatch.coordinate else { continue }
                let name = fishCatch.speciesName
                let when = fishCatch.timestamp.formatted(date: .abbreviated, time: .shortened)
                pins.append(HistoryMapPin(
                    id: fishCatch.id,
                    coordinate: coordinate,
                    title: name,
                    spokenLabel: "\(name), \(trip.displayName), \(when)",
                    species: fishCatch.species,
                    trip: trip
                ))
            }
        }
        return pins
    }

    /// Trip starting spots, leaving out trips listed in `tripIDs`.
    static func spotPins(for trips: [Trip], skipping tripIDs: Set<UUID> = []) -> [HistoryMapPin] {
        trips.compactMap { trip -> HistoryMapPin? in
            guard let coordinate = trip.coordinate, !tripIDs.contains(trip.id) else { return nil }
            let when = trip.startDate.formatted(date: .abbreviated, time: .omitted)
            return HistoryMapPin(
                id: trip.id,
                coordinate: coordinate,
                title: trip.displayName,
                spokenLabel: "Trip spot, \(trip.displayName), \(when)",
                species: nil,
                trip: trip
            )
        }
    }
}

/// Text helpers for the Log screens.
enum HistoryText {
    /// "5 h 35 min", "40 min", "2 h".
    static func duration(_ interval: TimeInterval) -> String {
        let minutes = max(0, Int(interval / 60))
        let hours = minutes / 60
        let rest = minutes % 60
        if hours == 0 { return "\(rest) min" }
        if rest == 0 { return "\(hours) h" }
        return "\(hours) h \(rest) min"
    }

    /// VoiceOver reads "h" as a letter, so spoken durations use full words.
    static func spokenDuration(_ interval: TimeInterval) -> String {
        let minutes = max(0, Int(interval / 60))
        let hours = minutes / 60
        let rest = minutes % 60
        let hourText = hours == 1 ? "1 hour" : "\(hours) hours"
        let minuteText = rest == 1 ? "1 minute" : "\(rest) minutes"
        if hours == 0 { return minuteText }
        if rest == 0 { return hourText }
        return "\(hourText) \(minuteText)"
    }

    static func fish(_ count: Int) -> String { "\(count) fish" }

    static func deleteMessage(for trip: Trip) -> String {
        let fishCount = trip.totalFish
        let photos = trip.catches.reduce(0) { $0 + $1.photos.count }
        let when = trip.startDate.formatted(date: .abbreviated, time: .omitted)
        var extras: [String] = []
        if fishCount > 0 { extras.append(fish(fishCount)) }
        if photos > 0 { extras.append(photos == 1 ? "1 photo" : "\(photos) photos") }
        let contents = extras.isEmpty ? "" : ", with \(extras.joined(separator: " and "))"
        return "\(trip.displayName) on \(when)\(contents). This cannot be undone."
    }
}

extension Trip {
    /// "6:10 AM to 11:45 AM", or "Started 6:10 AM" while the trip is running.
    var historyTimeRange: String {
        let start = startDate.formatted(date: .omitted, time: .shortened)
        guard let endDate else { return "Started \(start)" }
        let end: String
        if Calendar.current.isDate(endDate, inSameDayAs: startDate) {
            end = endDate.formatted(date: .omitted, time: .shortened)
        } else {
            end = endDate.formatted(.dateTime.month(.abbreviated).day().hour().minute())
        }
        return "\(start) to \(end)"
    }

    var historyDurationText: String { HistoryText.duration(duration) }

    var historySpokenDuration: String { HistoryText.spokenDuration(duration) }

    var historySpeciesCounts: [HistorySpeciesCount] {
        speciesTally.map { HistorySpeciesCount(speciesID: $0.speciesID, count: $0.count) }
    }

    /// True once the trip is deleted. Attributes of a deleted model can crash when read, so check this first.
    var historyIsGone: Bool { isDeleted || modelContext == nil }

    /// Case-insensitive match on the spot name or any species caught.
    func historyMatches(_ query: String) -> Bool {
        if displayName.localizedCaseInsensitiveContains(query) { return true }
        return catches.contains { $0.speciesName.localizedCaseInsensitiveContains(query) }
    }
}
