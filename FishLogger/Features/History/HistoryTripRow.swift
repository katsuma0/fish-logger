import SwiftData
import SwiftUI

/// One trip in the Trips list: where, when, how long, and what came in.
struct HistoryTripRow: View {
    let trip: Trip

    @Environment(AppSettings.self) private var settings
    /// Grows with the text so the species icons stay in step with their counts.
    @ScaledMetric(relativeTo: .caption) private var iconSize: CGFloat = 22

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

            // Wraps instead of squeezing at the largest text sizes.
            FlowLayout(spacing: 8, lineSpacing: 4) {
                Text(trip.historyTimeRange)
                if trip.isActive {
                    HistoryFishingNowBadge()
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            FlowLayout(spacing: 14, lineSpacing: 4) {
                durationLabel
                Label(HistoryText.fish(trip.totalFish), systemImage: "fish")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            if !tally.isEmpty {
                FlowLayout(spacing: 10, lineSpacing: 6) {
                    ForEach(Array(tally.prefix(Self.maxIcons))) { entry in
                        HStack(spacing: 3) {
                            SpeciesIcon(species: entry.species, size: min(iconSize, 40))
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

/// Green capsule shown on a trip that has not ended. Black text on the system green clears 4.5:1 in
/// light and dark mode, and on the darker green the system uses when Increase Contrast is on. White
/// text on green did not.
struct HistoryFishingNowBadge: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    init() {}

    var body: some View {
        let strong = settings.usesStrongContrast(colorSchemeContrast)
        Text("Fishing now")
            .font(.caption.weight(.bold))
            .foregroundStyle(Color.black)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Capsule().fill(Color(uiColor: .systemGreen)))
            .overlay(
                Capsule().strokeBorder(strong ? Color.primary : Color.clear, lineWidth: strong ? 1.5 : 0)
            )
            .fixedSize()
    }
}
