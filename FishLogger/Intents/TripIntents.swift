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
        // Starting again would quietly end the running trip, so say so instead.
        if let running = CatchLogger.activeTrip(in: context) {
            let message = "A trip is already running. It started \(tripIntentWhenText(running.startDate))."
            return .result(dialog: "\(message)")
        }
        let trip = CatchLogger.startTrip(in: context)
        Task {
            await TripConditionsUpdater.refresh(trip, in: context)
        }
        let message = "Trip started \(tripIntentWhenText(trip.startDate))."
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
        CatchLogger.endTrip(trip, in: context)
        let fish = trip.totalFish
        let duration = tripIntentDurationText(trip.duration)
        let message: String
        if fish == 0 {
            message = "Trip ended after \(duration). No fish logged."
        } else {
            message = "Trip ended. \(fish) fish in \(duration)."
        }
        return .result(dialog: "\(message)")
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
