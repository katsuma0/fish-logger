import SwiftData
import SwiftUI
import UIKit

/// Date, times, length, and where and how the trip was fished.
struct HistoryTripHeader: View {
    let trip: Trip

    init(trip: Trip) {
        self.trip = trip
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(trip.startDate.formatted(date: .complete, time: .omitted))
                .font(.headline)

            // Wraps instead of squeezing at the largest text sizes.
            FlowLayout(spacing: 8, lineSpacing: 4) {
                Text(trip.historyTimeRange)
                if trip.isActive {
                    HistoryFishingNowBadge()
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            durationLine
                .font(.subheadline)
                .foregroundStyle(.secondary)

            FlowLayout(spacing: 14, lineSpacing: 6) {
                Label(trip.waterBody.label, systemImage: trip.waterBody.symbolName)
                Label(trip.method.label, systemImage: trip.method.symbolName)
                Label(HistoryText.fish(trip.totalFish), systemImage: "fish")
            }
            .font(.subheadline)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spokenSummary)
    }

    /// A running trip's length ticks over once a minute.
    @ViewBuilder
    private var durationLine: some View {
        if trip.isActive {
            TimelineView(.everyMinute) { _ in
                Label(trip.historyDurationText, systemImage: "clock")
            }
        } else {
            Label(trip.historyDurationText, systemImage: "clock")
        }
    }

    private var spokenSummary: String {
        var parts: [String] = [trip.startDate.formatted(date: .complete, time: .omitted)]
        if trip.isActive {
            parts.append("Fishing now")
        }
        parts.append(trip.historyTimeRange)
        parts.append(trip.historySpokenDuration)
        parts.append(trip.waterBody.label)
        parts.append(trip.method.label)
        parts.append(HistoryText.fish(trip.totalFish))
        return parts.joined(separator: ", ")
    }
}

/// "Walleye 4" with the species icon, for the tally on a trip.
struct HistorySpeciesChip: View {
    let entry: HistorySpeciesCount

    @Environment(AppSettings.self) private var settings
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    init(entry: HistorySpeciesCount) {
        self.entry = entry
    }

    var body: some View {
        let strong = settings.usesStrongContrast(colorSchemeContrast)
        HStack(spacing: 6) {
            SpeciesIcon(species: entry.species, size: 20)
            Text("\(entry.name) \(entry.count)")
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
        .padding(.leading, 5)
        .padding(.trailing, 10)
        .padding(.vertical, 5)
        .background(Capsule().fill(Color(uiColor: .tertiarySystemFill)))
        .overlay(
            Capsule().strokeBorder(strong ? Color.primary : Color.clear, lineWidth: strong ? 1.5 : 0)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spokenLabel)
    }

    private var spokenLabel: String { "\(entry.name), \(HistoryText.fish(entry.count))" }
}

/// Horizontal strip of every photo on a trip. Tapping one opens the pager at that photo.
struct HistoryPhotoStrip: View {
    let photos: [CatchPhoto]
    let onOpen: (Int) -> Void

    init(photos: [CatchPhoto], onOpen: @escaping (Int) -> Void) {
        self.photos = photos
        self.onOpen = onOpen
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(photos.indices, id: \.self) { index in
                    Button {
                        onOpen(index)
                    } label: {
                        PhotoThumbnail(photo: photos[index], size: 84)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(spokenLabel(for: index))
                    .accessibilityHint("Opens the photo full screen")
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func spokenLabel(for index: Int) -> String {
        "Photo \(index + 1) of \(photos.count)"
    }
}
