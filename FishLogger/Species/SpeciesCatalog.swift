import Foundation

/// Lookup over the built-in species list. The lists live in the `SpeciesCatalog+*.swift` files.
enum SpeciesCatalog {
    static let unknownID = "unknown"

    /// Every species, Canada first, then the rest of North America by batch.
    static let all: [Species] = canadianSpecies + southernSpecies + bigRiverSpecies + westernSpecies
        + moreFreshwaterSpecies + northAtlanticSpecies + southCoastSpecies + offshoreSpecies + pacificCoastSpecies

    /// Placeholder for fish you could not identify. Not part of `all` so it stays out of browsing.
    static let unknown = Species(
        id: unknownID,
        commonName: "Unknown fish",
        otherNames: [],
        scientificName: "",
        group: .other,
        summary: "Logged without a species. You can fix it later.",
        idTips: [],
        lookalikes: [],
        traits: [],
        sizeCutoffsCm: [20, 30, 45, 60],
        weightA: nil,
        weightB: nil,
        colorHex: 0x8E8E93,
        habitat: "",
        range: ""
    )

    private static let byID: [String: Species] = {
        var map: [String: Species] = [unknownID: unknown]
        for species in all { map[species.id] = species }
        return map
    }()

    static func species(id: String) -> Species? { byID[id] }

    /// Alphabetical within each group, groups in declaration order. Empty groups are dropped.
    static let grouped: [(group: SpeciesGroup, species: [Species])] = SpeciesGroup.allCases.compactMap { group in
        let members = all.filter { $0.group == group }.sorted { $0.commonName < $1.commonName }
        return members.isEmpty ? nil : (group: group, species: members)
    }

    /// Prefix matches on any name rank above matches in the middle of a name.
    static func search(_ text: String) -> [Species] {
        let query = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return all.sorted { $0.commonName < $1.commonName } }
        let scored: [(Species, Int)] = all.compactMap { species in
            let names = species.searchableNames
            if names.contains(where: { $0.hasPrefix(query) }) { return (species, 0) }
            if names.contains(where: { $0.contains(query) }) { return (species, 1) }
            return nil
        }
        return scored
            .sorted { $0.1 == $1.1 ? $0.0.commonName < $1.0.commonName : $0.1 < $1.1 }
            .map(\.0)
    }

    /// Species caught in any of the regions, alphabetical. No regions means all of them.
    /// Worked out once per region set and cached, because the quick log, guide, and picker all ask
    /// on every render. Thread safe, since App Intents call in from off the main thread.
    static func available(in regions: Set<FishingRegion>) -> [Species] {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        if let cached = availableCache[regions] { return cached }
        let result = all.filter { $0.lives(in: regions) }.sorted { $0.commonName < $1.commonName }
        if availableCache.count >= maxCachedRegionSets { availableCache.removeAll() }
        availableCache[regions] = result
        return result
    }

    /// Like `grouped`, limited to the regions. Cached per region set like `available(in:)`.
    static func grouped(in regions: Set<FishingRegion>) -> [(group: SpeciesGroup, species: [Species])] {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        if let cached = groupedCache[regions] { return cached }
        let result: [(group: SpeciesGroup, species: [Species])] = grouped.compactMap { entry in
            let members = entry.species.filter { $0.lives(in: regions) }
            return members.isEmpty ? nil : (group: entry.group, species: members)
        }
        if groupedCache.count >= maxCachedRegionSets { groupedCache.removeAll() }
        groupedCache[regions] = result
        return result
    }

    /// Guards both caches. Never call one cached lookup from inside another while holding it.
    private static let cacheLock = NSLock()
    /// A person only ever has a few region sets in play; the cap just stops unbounded growth.
    private static let maxCachedRegionSets = 16
    nonisolated(unsafe) private static var availableCache: [Set<FishingRegion>: [Species]] = [:]
    nonisolated(unsafe) private static var groupedCache: [Set<FishingRegion>: [(group: SpeciesGroup, species: [Species])]] = [:]

    /// Roughly how often North American anglers target each fish, most first. Drives the starting
    /// quick log tiles, so a new install shows fish people actually catch, not alphabetical oddities.
    static let popularIDs: [String] = [
        "largemouth_bass", "walleye", "smallmouth_bass", "bluegill", "black_crappie", "channel_catfish",
        "red_drum", "spotted_seatrout", "rainbow_trout", "yellow_perch", "northern_pike", "brook_trout",
        "brown_trout", "striped_bass", "steelhead", "summer_flounder", "common_snook", "bluefish",
        "mahi_mahi", "red_snapper", "pacific_halibut", "lingcod", "kokanee", "sheepshead", "black_drum",
        "black_sea_bass", "tarpon", "yellowfin_tuna", "kelp_bass", "king_mackerel", "spanish_mackerel",
        "cobia", "tautog", "atlantic_cod", "black_rockfish", "california_halibut", "gray_snapper",
        "white_crappie", "spotted_bass", "lake_trout", "chinook_salmon", "coho_salmon", "white_bass",
        "pumpkinseed", "redear_sunfish", "blue_catfish", "flathead_catfish", "muskellunge", "cutthroat_trout",
        "sockeye_salmon", "rock_bass", "hybrid_striped_bass", "sauger", "saugeye", "florida_bass",
        "pink_salmon", "atlantic_salmon", "arctic_grayling", "lake_whitefish", "green_sunfish", "warmouth",
        "bull_trout", "dolly_varden", "arctic_char", "chum_salmon", "chain_pickerel", "brown_bullhead",
        "common_carp", "freshwater_drum", "white_perch", "yellow_bass", "guadalupe_bass", "alabama_bass",
        "shoal_bass", "redbreast_sunfish", "longear_sunfish", "peacock_bass", "splake", "tiger_muskie",
        "tiger_trout", "golden_trout", "mountain_whitefish", "burbot", "lake_sturgeon", "white_sturgeon",
        "paddlefish", "alligator_gar", "longnose_gar", "bowfin", "american_shad", "inconnu", "cisco"
    ]

    /// Best starting species for the chosen regions and kinds of fish, most popular first.
    /// Falls back to the whole region when the kinds of fish rule everything out.
    static func suggested(regions: Set<FishingRegion>, groups: Set<SpeciesGroup>, limit: Int = 12) -> [Species] {
        let local = popularityRanked.filter { $0.lives(in: regions) }
        let wanted = groups.isEmpty ? local : local.filter { groups.contains($0.group) }
        return Array((wanted.isEmpty ? local : wanted).prefix(limit))
    }

    /// Every species, most popular first, then the rest alphabetically. Built once.
    private static let popularityRanked: [Species] = {
        let popular = Set(popularIDs)
        return popularIDs.compactMap { species(id: $0) } +
            all.filter { !popular.contains($0.id) }.sorted { $0.commonName < $1.commonName }
    }()

    /// Species ranked by how many listed traits they have. Ties keep catalog order.
    static func matching(traits selected: Set<FishTrait>) -> [(species: Species, matches: Int)] {
        guard !selected.isEmpty else { return [] }
        return all
            .map { (species: $0, matches: $0.traits.intersection(selected).count) }
            .filter { $0.matches > 0 }
            .sorted { $0.matches > $1.matches }
    }
}
