import AppIntents
import Foundation
import SwiftData

/// "Log a walleye" from Siri, the Action button, or Shortcuts, without opening the app.
struct LogCatchIntent: AppIntent {
    static var title: LocalizedStringResource = "Log a Catch"
    static var description = IntentDescription("Logs a fish to the current trip. Starts a trip if none is running.")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Species")
    var species: SpeciesAppEntity

    @Parameter(title: "Count", default: 1, inclusiveRange: (1, 50))
    var count: Int

    @Parameter(title: "Size")
    var size: SizeClassAppEnum?

    static var parameterSummary: some ParameterSummary {
        Summary("Log \(\.$count) \(\.$species)") {
            \.$size
        }
    }

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let context = AppModelContainer.shared.mainContext
        // A forgotten trip gets closed by logCatch, so compare against the trip that was current.
        let tripBefore = CatchLogger.currentTrip(in: context)
        let fishCatch = CatchLogger.logCatch(
            speciesID: species.id,
            count: count,
            sizeClass: size?.sizeClass,
            in: context
        )
        if let trip = fishCatch.trip, trip.id != tripBefore?.id {
            // Conditions fill in after the reply, so Siri answers right away.
            Task {
                await TripConditionsUpdater.refresh(trip, in: context)
            }
        }
        let total = fishCatch.trip?.totalFish ?? fishCatch.count
        let logged = fishCatch.count == 1 ? species.name : "\(fishCatch.count) \(species.name)"
        let message = "Logged \(logged). \(total) fish this trip."
        return .result(dialog: "\(message)")
    }
}
