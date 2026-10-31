import SwiftUI

/// Asks about a trip that looks forgotten. Shown in the trip header's place, at about its height, so
/// the tiles stay where the thumb expects them.
struct TodayStaleTripCard: View {
    let trip: Trip
    let onEnd: () -> Void
    let onKeepGoing: () -> Void

    @Environment(AppSettings.self) private var settings
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// No fish for this long and the trip probably ended without anyone pressing End trip.
    static let quietInterval: TimeInterval = 8 * 60 * 60

    init(trip: Trip, onEnd: @escaping () -> Void, onKeepGoing: @escaping () -> Void) {
        self.trip = trip
        self.onEnd = onEnd
        self.onKeepGoing = onKeepGoing
    }

    /// A trip from an earlier day, or one quiet for 8 hours. After Keep going, only another quiet
    /// stretch brings the question back.
    static func isStale(_ trip: Trip, keptGoingAt: Date?, now: Date = .now) -> Bool {
        var lastActivity = lastCatchDate(in: trip) ?? trip.startDate
        lastActivity = max(lastActivity, trip.startDate)
        if let keptGoingAt { lastActivity = max(lastActivity, keptGoingAt) }
        if now.timeIntervalSince(lastActivity) > quietInterval { return true }
        return keptGoingAt == nil && trip.startDate < Calendar.current.startOfDay(for: now)
    }

    /// When the trip should end if the angler says it is over: at the last fish, or at the start.
    static func endDate(for trip: Trip) -> Date {
        lastCatchDate(in: trip) ?? trip.startDate
    }

    static func lastCatchDate(in trip: Trip) -> Date? {
        trip.catches.map(\.timestamp).max()
    }

    var body: some View {
        let lastCatch = Self.lastCatchDate(in: trip)
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.leading)
                Text(detail(lastCatch: lastCatch))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }
            .accessibilityElement(children: .combine)

            buttons(lastCatch: lastCatch)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardBackground()
    }

    private var title: String {
        let name = trip.locationName.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "Still fishing?" : "Still fishing at \(name)?"
    }

    private func detail(lastCatch: Date?) -> String {
        let when = lastCatch.map { "Last fish \(TodayFormat.when($0))." }
            ?? "Started \(TodayFormat.when(trip.startDate))."
        return "\(when) Logging a fish starts a new trip."
    }

    private func buttons(lastCatch: Date?) -> some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: 10))
            : AnyLayout(HStackLayout(spacing: 10))
        return layout {
            Button(action: onEnd) {
                Text("End it")
                    .frame(maxWidth: .infinity, minHeight: settings.buttonSize.minTapSize)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.accentFill)
            .accessibilityHint(lastCatch == nil ? "Ends the trip at its start time" : "Ends the trip at your last fish")

            Button(action: onKeepGoing) {
                Text("Keep going")
                    .frame(maxWidth: .infinity, minHeight: settings.buttonSize.minTapSize)
            }
            .buttonStyle(.bordered)
            .accessibilityHint("Keeps logging to this trip")
        }
        .font(.headline)
    }
}
