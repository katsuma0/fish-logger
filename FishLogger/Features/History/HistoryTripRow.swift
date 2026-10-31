import SwiftData
import SwiftUI

/// One trip in the Log list: where, when, how long, and what came in.
struct HistoryTripRow: View {
    let trip: Trip

    @Environment(AppSettings.self) private var settings

    private static let maxIcons = 5

    init(trip: Trip) {
        self.trip = trip
    }

    var body: some View {
        let tally = trip.historySpeciesCounts
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(trip.displayName)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer(minLength: 8)
                if let weather = trip.weather {
                    Image(systemName: weather.symbolName)
                        .symbolRenderingMode(.multicolor)
                        .font(.body)
                }
            }

            HStack(spacing: 8) {
                Text(trip.historyTimeRange)
                if trip.isActive {
                    HistoryFishingNowBadge()
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            HStack(spacing: 14) {
                durationLabel
                Label(HistoryText.fish(trip.totalFish), systemImage: "fish")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            if !tally.isEmpty {
                HStack(spacing: 10) {
                    ForEach(Array(tally.prefix(Self.maxIcons))) { entry in
                        HStack(spacing: 3) {
                            SpeciesIcon(species: entry.species, size: 22)
                            Text("\(entry.count)")
                                .font(.caption.weight(.semibold))
                                .monospacedDigit()
                                .foregroundStyle(.primary)
                        }
                    }
                    if tally.count > Self.maxIcons {
                        Text("+\(tally.count - Self.maxIcons)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .frame(minHeight: settings.buttonSize.minTapSize)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spokenSummary)
    }

    /// A running trip's length ticks over once a minute.
    @ViewBuilder
    private var durationLabel: some View {
        if trip.isActive {
            TimelineView(.everyMinute) { _ in
                Label(trip.historyDurationText, systemImage: "clock")
            }
        } else {
            Label(trip.historyDurationText, systemImage: "clock")
        }
    }

    private var spokenSummary: String {
        var parts: [String] = [trip.displayName]
        if trip.isActive {
            parts.append("Fishing now")
        }
        parts.append(trip.historyTimeRange)
        parts.append(trip.historySpokenDuration)
        parts.append(HistoryText.fish(trip.totalFish))
        let species = trip.historySpeciesCounts.map { "\($0.name) \($0.count)" }
        if !species.isEmpty {
            parts.append(species.joined(separator: ", "))
        }
        if let weather = trip.weather {
            parts.append(weather.label)
        }
        return parts.joined(separator: ", ")
    }
}

/// Green capsule shown on a trip that has not ended.
struct HistoryFishingNowBadge: View {
    @Environment(AppSettings.self) private var settings

    init() {}

    var body: some View {
        Text("Fishing now")
            .font(.caption.weight(.bold))
            .foregroundStyle(Color.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Capsule().fill(Color.green))
            .overlay(
                Capsule().strokeBorder(
                    settings.highContrast ? Color.primary : Color.clear,
                    lineWidth: settings.highContrast ? 1.5 : 0
                )
            )
            .fixedSize()
    }
}
