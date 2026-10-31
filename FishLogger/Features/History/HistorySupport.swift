import CoreLocation
import Foundation
import SwiftData

/// Time windows offered in the Trips filter menu. Same choices, labels and order as Stats.
enum HistoryTimeFilter: String, CaseIterable, Identifiable {
    case last30Days, thisMonth, thisYear, allTime

    var id: String { rawValue }

    var label: String {
        switch self {
        case .last30Days: "Last 30 days"
        case .thisMonth: "This month"
        case .thisYear: "This year"
        case .allTime: "All time"
        }
    }

    func includes(_ date: Date, now: Date = .now, calendar: Calendar = .current) -> Bool {
        guard let range = dateRange(now: now, calendar: calendar) else { return true }
        return range.contains(date)
    }

    /// The window as plain dates, worked out once per filter pass so each trip costs a comparison
    /// rather than a calendar lookup. Nil means no limit.
    func dateRange(now: Date = .now, calendar: Calendar = .current) -> Range<Date>? {
        switch self {
        case .allTime:
            return nil
        case .last30Days:
            // Today plus the 29 days before it, counted in whole days so a morning trip a month ago does not flicker in and out.
            let today = calendar.startOfDay(for: now)
            guard let start = calendar.date(byAdding: .day, value: -29, to: today) else { return nil }
            return start..<Date.distantFuture
        case .thisMonth:
            guard let interval = calendar.dateInterval(of: .month, for: now) else { return nil }
            return interval.start..<interval.end
        case .thisYear:
            guard let interval = calendar.dateInterval(of: .year, for: now) else { return nil }
            return interval.start..<interval.end
        }
    }

    /// Midnight to midnight for a day picked from the calendar.
    static func dayRange(for day: Date, calendar: Calendar = .current) -> Range<Date>? {
        guard let interval = calendar.dateInterval(of: .day, for: day) else { return nil }
        return interval.start..<interval.end
    }
}

/// Trips that started on one calendar day, newest first.
struct HistoryDayGroup: Identifiable {
    let day: Date
    var trips: [Trip]

    var id: Date { day }

    var totalFish: Int { trips.reduce(0) { $0 + $1.totalFish } }

    /// "Sat, Oct 26", with the year added for earlier years.
    var title: String { HistoryText.dayTitle(day) }
}

/// One species and how many of it, ready for ForEach.
struct HistorySpeciesCount: Identifiable {
    let speciesID: String
    let count: Int

    var id: String { speciesID }
    var species: Species? { SpeciesCatalog.species(id: speciesID) }
    var name: String { species?.commonName ?? "Unknown fish" }
}

/// A point on one of the Trips maps: a geotagged catch, a trip's catches grouped, or a trip spot.
struct HistoryMapPin: Identifiable {
    let id: UUID
    let coordinate: CLLocationCoordinate2D
    let title: String
    let spokenLabel: String
    let species: Species?
    let trip: Trip?
}

/// Folded search text and species ids for each trip, keyed by trip id. Built once per data change so
/// each keystroke in search only runs `contains` on a string that is already there.
struct HistorySearchIndex {
    var text: [UUID: String]
    var speciesIDs: [UUID: Set<String>]

    init(text: [UUID: String] = [:], speciesIDs: [UUID: Set<String>] = [:]) {
        self.text = text
        self.speciesIDs = speciesIDs
    }
}

@MainActor
enum HistoryTripFilter {
    /// Pass `index` from `searchIndex(for:)` to keep typing fast. Without it, every catch is read again.
    /// A picked `day` wins over `time`; the Trips screen only ever sets one of them.
    static func apply(
        _ trips: [Trip],
        search: String,
        speciesID: String?,
        time: HistoryTimeFilter,
        day: Date? = nil,
        index: HistorySearchIndex? = nil,
        now: Date = .now
    ) -> [Trip] {
        let query = HistoryText.folded(search.trimmingCharacters(in: .whitespacesAndNewlines))
        let range: Range<Date>?
        if let day {
            range = HistoryTimeFilter.dayRange(for: day)
        } else {
            range = time.dateRange(now: now)
        }
        if range == nil, speciesID == nil, query.isEmpty { return trips }
        return trips.filter { trip in
            if trip.historyIsGone { return false }
            if let range, !range.contains(trip.startDate) { return false }
            let tripID = trip.id
            if let speciesID {
                if let ids = index?.speciesIDs[tripID] {
                    if !ids.contains(speciesID) { return false }
                } else if !trip.catches.contains(where: { $0.speciesID == speciesID }) {
                    return false
                }
            }
            if query.isEmpty { return true }
            if let text = index?.text[tripID] { return text.contains(query) }
            return trip.historyMatches(query)
        }
    }

    /// Spot name, the day in short and long form, and every species name, for each trip. Days are
    /// formatted once each, since most days hold one or two trips.
    static func searchIndex(for trips: [Trip]) -> HistorySearchIndex {
        var text: [UUID: String] = [:]
        var speciesIDs: [UUID: Set<String>] = [:]
        text.reserveCapacity(trips.count)
        speciesIDs.reserveCapacity(trips.count)
        var dayTexts: [Date: String] = [:]
        let calendar = Calendar.current
        for trip in trips where !trip.historyIsGone {
            let day = calendar.startOfDay(for: trip.startDate)
            let dayText: String
            if let cached = dayTexts[day] {
                dayText = cached
            } else {
                dayText = HistoryText.searchableDayText(day)
                dayTexts[day] = dayText
            }
            var ids = Set<String>()
            var names = Set<String>()
            for fishCatch in trip.catches {
                ids.insert(fishCatch.speciesID)
                names.insert(fishCatch.speciesName)
            }
            let parts = [trip.displayName, dayText] + names.sorted()
            let tripID = trip.id
            text[tripID] = HistoryText.folded(parts.joined(separator: "\n"))
            speciesIDs[tripID] = ids
        }
        return HistorySearchIndex(text: text, speciesIDs: speciesIDs)
    }

    /// Expects trips newest first, which is how the Trips tab queries them, so each day is one contiguous run.
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
        return species(for: ids)
    }

    /// Same as `loggedSpecies(in:)` from one light fetch of species ids, so it never walks every trip's catches.
    static func loggedSpecies(in context: ModelContext) -> [Species] {
        var descriptor = FetchDescriptor<FishCatch>()
        descriptor.propertiesToFetch = [\.speciesID]
        let catches = (try? context.fetch(descriptor)) ?? []
        var ids = Set<String>()
        for fishCatch in catches {
            ids.insert(fishCatch.speciesID)
        }
        return species(for: ids)
    }

    private static func species(for ids: Set<String>) -> [Species] {
        ids
            .compactMap { SpeciesCatalog.species(id: $0) }
            .sorted { $0.commonName < $1.commonName }
    }
}

@MainActor
enum HistoryMapPins {
    /// Above this many catch pins the Trips map shows one pin per trip, so panning stays smooth on a big log.
    static let groupingThreshold = 300

    /// Catches with a location, optionally only one species. Stops once it has `limit` pins, so a big
    /// log never builds thousands of pins only to have them grouped per trip.
    static func catchPins(for trips: [Trip], speciesID: String?, limit: Int = .max) -> [HistoryMapPin] {
        var pins: [HistoryMapPin] = []
        for trip in trips where !trip.historyIsGone {
            let tripName = trip.displayName
            for fishCatch in trip.catches {
                if let speciesID, fishCatch.speciesID != speciesID { continue }
                guard let coordinate = fishCatch.coordinate else { continue }
                if pins.count >= limit { return pins }
                let name = fishCatch.speciesName
                pins.append(HistoryMapPin(
                    id: fishCatch.id,
                    coordinate: coordinate,
                    title: name,
                    spokenLabel: "\(name), \(tripName)",
                    species: fishCatch.species,
                    trip: trip
                ))
            }
        }
        return pins
    }

    /// Pins for one trip's page, from catches the page already sorted. A trip holds few catches, so
    /// each title carries the time.
    static func catchPins(for catches: [FishCatch], in trip: Trip) -> [HistoryMapPin] {
        catches.compactMap { fishCatch -> HistoryMapPin? in
            guard let coordinate = fishCatch.coordinate else { return nil }
            let name = fishCatch.speciesName
            let time = fishCatch.timestamp.formatted(date: .omitted, time: .shortened)
            return HistoryMapPin(
                id: fishCatch.id,
                coordinate: coordinate,
                title: "\(name), \(time)",
                spokenLabel: "\(name), \(time)",
                species: fishCatch.species,
                trip: trip
            )
        }
    }

    /// One pin per trip at the middle of its geotagged catches, tinted for the species caught most.
    static func tripPins(for trips: [Trip], speciesID: String?) -> [HistoryMapPin] {
        var pins: [HistoryMapPin] = []
        for trip in trips where !trip.historyIsGone {
            var latitude = 0.0
            var longitude = 0.0
            var located = 0
            var fish = 0
            var tally: [String: Int] = [:]
            for fishCatch in trip.catches {
                if let speciesID, fishCatch.speciesID != speciesID { continue }
                guard let catchLatitude = fishCatch.latitude, let catchLongitude = fishCatch.longitude else { continue }
                latitude += catchLatitude
                longitude += catchLongitude
                located += 1
                fish += fishCatch.count
                tally[fishCatch.speciesID, default: 0] += fishCatch.count
            }
            guard located > 0 else { continue }
            let topSpeciesID = tally.max { lhs, rhs in
                lhs.value == rhs.value ? lhs.key > rhs.key : lhs.value < rhs.value
            }?.key
            let title = "\(trip.displayName), \(HistoryText.fish(fish))"
            pins.append(HistoryMapPin(
                id: trip.id,
                coordinate: CLLocationCoordinate2D(
                    latitude: latitude / Double(located),
                    longitude: longitude / Double(located)
                ),
                title: title,
                spokenLabel: title,
                species: topSpeciesID.flatMap { SpeciesCatalog.species(id: $0) },
                trip: trip
            ))
        }
        return pins
    }

    /// Trip starting spots, leaving out trips listed in `tripIDs`.
    static func spotPins(for trips: [Trip], skipping tripIDs: Set<UUID> = []) -> [HistoryMapPin] {
        trips.compactMap { trip -> HistoryMapPin? in
            guard !trip.historyIsGone, let coordinate = trip.coordinate, !tripIDs.contains(trip.id) else { return nil }
            let name = trip.displayName
            return HistoryMapPin(
                id: trip.id,
                coordinate: coordinate,
                title: name,
                spokenLabel: "Trip spot, \(name)",
                species: nil,
                trip: trip
            )
        }
    }

    /// Everything the Trips map draws: catches (grouped per trip on a big log) and the spots of trips
    /// that have no located catch.
    static func mapPins(for trips: [Trip], speciesID: String?) -> (catches: [HistoryMapPin], spots: [HistoryMapPin]) {
        // One pin past the threshold is enough to know the log gets grouped.
        var catches = catchPins(for: trips, speciesID: speciesID, limit: groupingThreshold + 1)
        if catches.count > groupingThreshold {
            catches = tripPins(for: trips, speciesID: speciesID)
        }
        let tripsWithPins = Set(catches.compactMap { $0.trip?.id })
        let spots = spotPins(for: trips, skipping: tripsWithPins)
        return (catches: catches, spots: spots)
    }
}

/// Text helpers for the Trips screens.
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

    /// "Sat, Oct 26", with the year added for earlier years. Day headers, the day chip and the day picker share it.
    static func dayTitle(_ day: Date, now: Date = .now) -> String {
        if Calendar.current.isDate(day, equalTo: now, toGranularity: .year) {
            return day.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
        }
        return day.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day().year())
    }

    /// The short and long ways of writing a day, so search finds "sat", "oct 26" and "october".
    static func searchableDayText(_ day: Date) -> String {
        let short = day.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
        let long = day.formatted(.dateTime.weekday(.wide).month(.wide).day().year())
        return "\(short)\n\(long)"
    }

    /// Lowercased with accents dropped, so "Éperlan" and "eperlan" match.
    static func folded(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }

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

    /// "Walleye at 6:42 AM. Its 2 photos go with it. This cannot be undone."
    static func catchDeleteMessage(for fishCatch: FishCatch) -> String {
        let time = fishCatch.timestamp.formatted(date: .omitted, time: .shortened)
        let photos = fishCatch.photos.count
        let photoText: String
        switch photos {
        case 0: photoText = ""
        case 1: photoText = " Its photo goes with it."
        default: photoText = " Its \(photos) photos go with it."
        }
        return "\(fishCatch.speciesName) at \(time).\(photoText) This cannot be undone."
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

    /// Case and accent insensitive match on the spot name or any species caught. The search index
    /// does the same match faster; this is the fallback when there is none.
    func historyMatches(_ query: String) -> Bool {
        if displayName.localizedStandardContains(query) { return true }
        return catches.contains { $0.speciesName.localizedStandardContains(query) }
    }
}
