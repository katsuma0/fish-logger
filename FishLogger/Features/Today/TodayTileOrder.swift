import Foundation

/// The quick log grid's species, in order. Frozen for the life of a trip so a tile never moves under
/// the thumb: counts change in place, and a species new to the grid goes at the end. The grid is
/// re-ranked only between trips.
struct TodayTileOrder: Equatable {
    /// The trip this order belongs to, or nil for the grid shown when no trip is running.
    var tripID: UUID?
    var speciesIDs: [String]
    /// How many tiles are settled: the ranked ones, and any kept on purpose since. Tiles after these
    /// were added during the trip, so trailing ones can go again (after an Undo, say) without moving
    /// any tile before them.
    var rankedCount: Int

    /// Suggested tiles shown while there are no favourites. Favourites are never capped.
    static let maxRankedTiles = 12
    static let empty = TodayTileOrder(tripID: nil, speciesIDs: [], rankedCount: 0)

    private static let storageKey = "todayTileOrder"

    /// The angler's favourites in their order, and only those, once there are any. Until then, their
    /// usual catches and popular fish for their regions and the kinds of fish they picked at setup,
    /// so a new install still has a useful grid.
    static func ranked(
        tripID: UUID?,
        favourites: [String],
        mostLogged: [String],
        suggested: [String]
    ) -> TodayTileOrder {
        var seen = Set<String>()
        var ids: [String] = []
        for id in favourites where isTileSpecies(id) && seen.insert(id).inserted {
            ids.append(id)
        }
        if ids.isEmpty {
            for id in mostLogged + suggested {
                guard ids.count < maxRankedTiles else { break }
                guard isTileSpecies(id), seen.insert(id).inserted else { continue }
                ids.append(id)
            }
        }
        return TodayTileOrder(tripID: tripID, speciesIDs: ids, rankedCount: ids.count)
    }

    /// True once at least one favourite can have a tile, so the grid is the angler's favourites
    /// rather than suggestions.
    static func hasTileFavourites(_ favourites: [String]) -> Bool {
        favourites.contains { isTileSpecies($0) }
    }

    /// Adds species that need a tile, such as one just caught through Other fish, at the end.
    mutating func appendMissing(_ ids: [String]) {
        var present = Set(speciesIDs)
        for id in ids where Self.isTileSpecies(id) && present.insert(id).inserted {
            speciesIDs.append(id)
        }
    }

    /// Drops tiles added during the trip that are no longer needed, from the end only, so no other
    /// tile moves.
    mutating func trimTrailing(keeping needed: Set<String>) {
        while speciesIDs.count > rankedCount, let last = speciesIDs.last, !needed.contains(last) {
            speciesIDs.removeLast()
        }
    }

    /// Settles a tile added during the trip, such as one whose catches were just reset, so trimming
    /// never takes it away. Every tile before it is settled too, so nothing moves.
    mutating func keep(_ id: String) {
        guard let index = speciesIDs.firstIndex(of: id), index >= rankedCount else { return }
        rankedCount = index + 1
    }

    /// Unknown fish have no tile of their own; Other fish covers them.
    private static func isTileSpecies(_ id: String) -> Bool {
        id != SpeciesCatalog.unknownID && SpeciesCatalog.species(id: id) != nil
    }

    // MARK: Storage

    /// Kept across launches, so the grid looks the same after the app is closed mid-trip.
    static func load(from defaults: UserDefaults = .standard) -> TodayTileOrder {
        guard let raw = defaults.string(forKey: storageKey) else { return .empty }
        let parts = raw.components(separatedBy: "|")
        guard parts.count == 3, let ranked = Int(parts[1]) else { return .empty }
        var tripID: UUID?
        if !parts[0].isEmpty {
            guard let parsed = UUID(uuidString: parts[0]) else { return .empty }
            tripID = parsed
        }
        let ids = parts[2].isEmpty ? [] : parts[2].components(separatedBy: ",")
        return TodayTileOrder(tripID: tripID, speciesIDs: ids, rankedCount: max(0, min(ranked, ids.count)))
    }

    func save(to defaults: UserDefaults = .standard) {
        let raw = [tripID?.uuidString ?? "", String(rankedCount), speciesIDs.joined(separator: ",")]
            .joined(separator: "|")
        defaults.set(raw, forKey: Self.storageKey)
    }
}
