import Foundation

/// Lookup over the built-in species list. The lists live in the `SpeciesCatalog+*.swift` files.
enum SpeciesCatalog {
    static let unknownID = "unknown"

    /// Every species, Canada first, then the rest of North America by batch.
    static let all: [Species] = canadianSpecies + southernSpecies + bigRiverSpecies + westernSpecies

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
    static func available(in regions: Set<FishingRegion>) -> [Species] {
        all.filter { $0.lives(in: regions) }.sorted { $0.commonName < $1.commonName }
    }

    /// Like `grouped`, limited to the regions.
    static func grouped(in regions: Set<FishingRegion>) -> [(group: SpeciesGroup, species: [Species])] {
        grouped.compactMap { entry in
            let members = entry.species.filter { $0.lives(in: regions) }
            return members.isEmpty ? nil : (group: entry.group, species: members)
        }
    }

    /// Roughly how often North American anglers target each fish, most first. Drives the starting
    /// quick log tiles, so a new install shows fish people actually catch, not alphabetical oddities.
    static let popularIDs: [String] = [
        "largemouth_bass", "walleye", "smallmouth_bass", "bluegill", "black_crappie", "channel_catfish",
        "rainbow_trout", "yellow_perch", "northern_pike", "brook_trout", "brown_trout", "striped_bass",
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
        let ranked = popularIDs.compactMap { species(id: $0) } +
            all.filter { !popularIDs.contains($0.id) }.sorted { $0.commonName < $1.commonName }
        let local = ranked.filter { $0.lives(in: regions) }
        let wanted = groups.isEmpty ? local : local.filter { groups.contains($0.group) }
        return Array((wanted.isEmpty ? local : wanted).prefix(limit))
    }

    /// Species ranked by how many listed traits they have. Ties keep catalog order.
    static func matching(traits selected: Set<FishTrait>) -> [(species: Species, matches: Int)] {
        guard !selected.isEmpty else { return [] }
        return all
            .map { (species: $0, matches: $0.traits.intersection(selected).count) }
            .filter { $0.matches > 0 }
            .sorted { $0.matches > $1.matches }
    }
}
