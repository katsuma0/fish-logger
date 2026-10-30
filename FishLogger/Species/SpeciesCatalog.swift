import Foundation

/// Lookup over the built-in species list. The list itself lives in `SpeciesCatalog+Data.swift`.
enum SpeciesCatalog {
    static let unknownID = "unknown"

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
    static var grouped: [(group: SpeciesGroup, species: [Species])] {
        SpeciesGroup.allCases.compactMap { group in
            let members = all.filter { $0.group == group }.sorted { $0.commonName < $1.commonName }
            return members.isEmpty ? nil : (group: group, species: members)
        }
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

    /// Species ranked by how many listed traits they have. Ties keep catalog order.
    static func matching(traits selected: Set<FishTrait>) -> [(species: Species, matches: Int)] {
        guard !selected.isEmpty else { return [] }
        return all
            .map { (species: $0, matches: $0.traits.intersection(selected).count) }
            .filter { $0.matches > 0 }
            .sorted { $0.matches > $1.matches }
    }
}
