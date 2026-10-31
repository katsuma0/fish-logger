import Foundation
import SwiftData

/// The numbers at the top of "Your catches" on a species page, over every catch of that species.
/// Worked out from a four-field fetch in one pass, so a species that fills most of a long log never
/// loads its catches in full or wakes each of their trips.
struct SpeciesCatchTotals: Equatable {
    /// Log entries, so the page can say when it shows only the latest ones.
    var entries = 0
    /// Fish, counting multi-fish entries.
    var fish = 0
    var trips = 0
    /// Measured fish only, so a bucketed "trophy" never passes for a record.
    var longestCm: Double?
    var heaviestKg: Double?

    init() {}

    /// Runs on the main actor because the view's context lives there. Cheap enough to run after
    /// every save while the page is open.
    @MainActor
    static func load(speciesID: String, in context: ModelContext) -> SpeciesCatchTotals {
        let wanted = speciesID
        var descriptor = FetchDescriptor<FishCatch>(predicate: #Predicate<FishCatch> { $0.speciesID == wanted })
        // The trip is in the list too. Reading a property left out would load each catch again, one
        // store query per catch.
        descriptor.propertiesToFetch = [\.count, \.lengthCm, \.weightKg, \.trip]
        let catches: [FishCatch]
        if let partial = try? context.fetch(descriptor) {
            catches = partial
        } else {
            // Should the store turn down the partial fetch, a full one still gives the right numbers.
            descriptor.propertiesToFetch = []
            catches = (try? context.fetch(descriptor)) ?? []
        }

        var totals = SpeciesCatchTotals()
        // Trips are told apart by their store identity, which never loads the trip itself.
        var tripIDs = Set<PersistentIdentifier>()
        for fishCatch in catches where !fishCatch.isDeleted {
            totals.entries += 1
            totals.fish += fishCatch.count
            if let tripID = fishCatch.trip?.persistentModelID {
                tripIDs.insert(tripID)
            }
            if let length = fishCatch.lengthCm {
                totals.longestCm = max(totals.longestCm ?? length, length)
            }
            if let weight = fishCatch.weightKg {
                totals.heaviestKg = max(totals.heaviestKg ?? weight, weight)
            }
        }
        totals.trips = tripIDs.count
        return totals
    }
}
