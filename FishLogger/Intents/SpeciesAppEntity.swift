import AppIntents
import Foundation

/// A catalog species as Siri and Shortcuts see it. Only the id travels; everything else comes from the catalog.
struct SpeciesAppEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Species"
    static var defaultQuery = SpeciesEntityQuery()

    let id: String
    let name: String
    let scientificName: String

    init(species: Species) {
        self.id = species.id
        self.name = species.commonName
        self.scientificName = species.scientificName
    }

    var displayRepresentation: DisplayRepresentation {
        if scientificName.isEmpty {
            return DisplayRepresentation(title: "\(name)")
        }
        return DisplayRepresentation(title: "\(name)", subtitle: "\(scientificName)")
    }
}

/// Looks species up in the built-in catalog. No database access, so it is safe off the main actor.
struct SpeciesEntityQuery: EntityStringQuery {
    init() {}

    func entities(for identifiers: [String]) async throws -> [SpeciesAppEntity] {
        identifiers
            .compactMap { SpeciesCatalog.species(id: $0) }
            .map { SpeciesAppEntity(species: $0) }
    }

    func entities(matching string: String) async throws -> [SpeciesAppEntity] {
        SpeciesCatalog.search(string).map { SpeciesAppEntity(species: $0) }
    }

    /// Favourites first, in the order you pinned them, then the rest of the catalog by name.
    func suggestedEntities() async throws -> [SpeciesAppEntity] {
        let favouriteIDs = AppSettings.shared.favouriteSpeciesIDs
        let favourites = favouriteIDs
            .filter { $0 != SpeciesCatalog.unknownID }
            .compactMap { SpeciesCatalog.species(id: $0) }
        let others = SpeciesCatalog.all
            .filter { !favouriteIDs.contains($0.id) }
            .sorted { $0.commonName < $1.commonName }
        return (favourites + others).map { SpeciesAppEntity(species: $0) }
    }
}
