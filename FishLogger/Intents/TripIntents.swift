import AppIntents
import Foundation
import SwiftData

/// "Start fishing" hands-free. Location, weather, moon, and sun fill in after the reply.
struct StartTripIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Fishing"
    static var description = IntentDescription("Starts a fishing trip now. Location and weather fill in on their own.")
    static var openAppWhenRun: Bool = false

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let context = AppModelContainer.shared.mainContext
        var closedNote = ""
        if let running = CatchLogger.activeTrip(in: context) {
            // Starting again would quietly end a trip that is still going, so say so instead.
            guard CatchLogger.isForgotten(running) else {
                let message = "A trip is already running. It started \(tripIntentWhenText(running.startDate))."
                return .result(dialog: "\(message)")
            }
            // Logging a fish would close a trip this quiet anyway, so starting does the same.
            let when = tripIntentWhenText(running.startDate)
            closedNote = CatchLogger.lastCatchDate(in: running) == nil
                ? "The trip that started \(when) was left running with no fish, so I ended it. "
                : "The trip that started \(when) was left running, so I ended it at your last fish. "
            CatchLogger.endTrip(running, in: context, at: CatchLogger.forgottenTripEndDate(for: running))
        }
        let trip = CatchLogger.startTrip(in: context)
        Task {
            await TripConditionsUpdater.refresh(trip, in: context)
        }
        let message = "\(closedNote)Trip started \(tripIntentWhenText(trip.startDate))."
        return .result(dialog: "\(message)")
    }
}

/// Ends the running trip and reads back the day in one line.
struct EndTripIntent: AppIntent {
    static var title: LocalizedStringResource = "End Fishing Trip"
    static var description = IntentDescription("Ends the trip that is running and tells you how many fish you logged.")
    static var openAppWhenRun: Bool = false

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let context = AppModelContainer.shared.mainContext
        guard let trip = CatchLogger.activeTrip(in: context) else {
            return .result(dialog: "No trip is running.")
        }
        let now = Date.now
        let forgotten = Self.isForgotten(trip, now: now)
        let hadFish = CatchLogger.lastCatchDate(in: trip) != nil
        CatchLogger.endTrip(trip, in: context, at: forgotten ? CatchLogger.forgottenTripEndDate(for: trip) : now)
        let fish = trip.totalFish
        let duration = tripIntentDurationText(trip.duration)
        let message: String
        if forgotten {
            // Siri cannot ask "Still fishing?" first, so it says where the trip was cut off.
            let when = tripIntentWhenText(trip.startDate)
            if hadFish {
                message = "That trip started \(when), so I ended it at your last fish. \(fish) fish in \(duration). You can change the end time in the Trips tab."
            } else {
                message = "That trip started \(when) and has no fish, so I ended it at its start time. You can change the end time in the Trips tab."
            }
        } else if fish == 0 {
            message = "Trip ended after \(duration). No fish logged."
        } else {
            message = "Trip ended. \(fish) fish in \(duration)."
        }
        return .result(dialog: "\(message)")
    }

    /// A trip left running from an earlier day, quiet long enough that logging a fish would treat it
    /// as over too. Same quiet rule and Keep going answer as logging, but only for earlier days:
    /// a long, quiet trip today may be real, and ending it at its last fish would cut it short.
    @MainActor
    private static func isForgotten(_ trip: Trip, now: Date) -> Bool {
        trip.startDate < Calendar.current.startOfDay(for: now) && CatchLogger.isForgotten(trip, now: now)
    }
}

/// "at 6:42 AM" for today, "on Oct 30, 2026 at 6:42 AM" for a trip left running from another day.
private func tripIntentWhenText(_ date: Date) -> String {
    if Calendar.current.isDateInToday(date) {
        return "at \(date.formatted(date: .omitted, time: .shortened))"
    }
    return "on \(date.formatted(date: .abbreviated, time: .shortened))"
}

/// "3 h 10 min", "45 min", "2 h". Spoken by Siri, so no seconds.
private func tripIntentDurationText(_ seconds: TimeInterval) -> String {
    let totalMinutes = Int((max(0, seconds) / 60).rounded())
    let hours = totalMinutes / 60
    let minutes = totalMinutes % 60
    if hours == 0 {
        return totalMinutes == 0 ? "less than a minute" : "\(minutes) min"
    }
    if minutes == 0 { return "\(hours) h" }
    return "\(hours) h \(minutes) min"
}
