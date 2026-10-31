import Foundation

/// The quick log grid's species, in order. Frozen for the life of a trip so a tile never moves under
/// the thumb: counts change in place, and a species new to the grid goes at the end. The grid is
/// re-ranked only between trips, so fish caught often still move up next time.
struct TodayTileOrder: Equatable {
    /// The trip this order belongs to, or nil for the grid shown when no trip is running.
    var tripID: UUID?
    var speciesIDs: [String]
    /// How many tiles came from ranking. Tiles after these were added during the trip, so trailing
    /// ones can go again (after an Undo, say) without moving any tile before them.
    var rankedCount: Int

    /// Ranked tiles before the trip adds any. Favourites can go past it; they are never dropped.
    static let maxRankedTiles = 12
    static let empty = TodayTileOrder(tripID: nil, speciesIDs: [], rankedCount: 0)

    private static let storageKey = "todayTileOrder"

    /// Every favourite in the angler's order, then their usual catches, then popular fish for their
    /// regions and the kinds of fish they picked at setup, so a new install still has a useful grid.
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
        for id in mostLogged + suggested {
            guard ids.count < maxRankedTiles else { break }
            guard isTileSpecies(id), seen.insert(id).inserted else { continue }
            ids.append(id)
        }
        return TodayTileOrder(tripID: tripID, speciesIDs: ids, rankedCount: ids.count)
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
