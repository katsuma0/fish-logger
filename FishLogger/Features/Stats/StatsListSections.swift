import SwiftUI

/// Biggest fish per species. Tapping a row opens the record catch itself, and the book button
/// beside it opens the species guide page.
struct StatsPersonalBestsSection: View {
    let bests: [StatsCalculator.PersonalBest]
    /// Called with the record catch's id. The screen looks the catch up and opens it.
    let onOpenCatch: (UUID) -> Void

    init(bests: [StatsCalculator.PersonalBest], onOpenCatch: @escaping (UUID) -> Void = { _ in }) {
        self.bests = bests
        self.onOpenCatch = onOpenCatch
    }

    var body: some View {
        StatsSectionCard(
            "Personal bests",
            footer: "Longest and heaviest come from measured fish only. Tap a record to open that catch."
        ) {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(bests) { best in
                    if best.id != bests.first?.id {
                        Divider()
                    }
                    StatsPersonalBestRow(best: best, onOpenCatch: onOpenCatch)
                }
            }
        }
    }
}

private struct StatsPersonalBestRow: View {
    let best: StatsCalculator.PersonalBest
    let onOpenCatch: (UUID) -> Void

    @Environment(AppSettings.self) private var settings

    init(best: StatsCalculator.PersonalBest, onOpenCatch: @escaping (UUID) -> Void) {
        self.best = best
        self.onOpenCatch = onOpenCatch
    }

    var body: some View {
        let species = best.species
        HStack(spacing: 4) {
            if let catchID = best.recordCatchID {
                Button {
                    onOpenCatch(catchID)
                } label: {
                    summary(species: species)
                }
                .buttonStyle(.plain)
                .accessibilityHint("Opens this catch.")
            } else {
                summary(species: species)
            }

            if let species {
                NavigationLink {
                    SpeciesDetailView(species: species)
                } label: {
                    Image(systemName: "book")
                        .font(.body)
                        .frame(minWidth: settings.buttonSize.minTapSize, minHeight: settings.buttonSize.minTapSize)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("\(best.name) species guide")
            }
        }
    }

    private func summary(species: Species?) -> some View {
        HStack(spacing: 12) {
            SpeciesIcon(species: species, size: settings.buttonSize.iconSize + 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(best.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                ForEach(detailLines, id: \.self) { line in
                    Text(line)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 8)
        }
        .padding(.vertical, 8)
        .frame(minHeight: settings.buttonSize.minTapSize)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private var detailLines: [String] {
        var lines: [String] = []
        if let longest = best.longestCm {
            lines.append("Longest \(settings.length(longest))" + Self.onDate(best.longestCatchDate))
        }
        if let heaviest = best.heaviestKg {
            lines.append("Heaviest \(settings.weight(heaviest))" + Self.onDate(best.heaviestCatchDate))
        }
        if let biggest = best.biggestClass {
            lines.append("Biggest: \(biggest.label)")
        }
        if lines.isEmpty {
            lines.append("No size logged yet")
        }
        return lines
    }

    private static func onDate(_ date: Date?) -> String {
        guard let date else { return "" }
        return " on \(date.formatted(date: .abbreviated, time: .omitted))"
    }
}

/// Where the fish came from, most fish first. Each row lists that spot's trips in this range.
struct StatsTopSpotsSection: View {
    let spots: [StatsCalculator.SpotCount]
    /// Shown above the trip list, for example "Last 30 days".
    let scopeLabel: String

    @Environment(AppSettings.self) private var settings

    init(spots: [StatsCalculator.SpotCount], scopeLabel: String = StatsRange.allTime.label) {
        self.spots = spots
        self.scopeLabel = scopeLabel
    }

    var body: some View {
        StatsSectionCard("Top spots") {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(spots) { spot in
                    if spot.id != spots.first?.id {
                        Divider()
                    }
                    NavigationLink {
                        StatsSpotTripsView(spot: spot, scopeLabel: scopeLabel)
                    } label: {
                        row(for: spot)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Lists the trips here.")
                }
            }
        }
    }

    private func row(for spot: StatsCalculator.SpotCount) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "mappin.and.ellipse")
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: settings.buttonSize.iconSize)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(spot.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                Text("\(StatsFormat.fish(spot.fish)), \(StatsFormat.trips(spot.trips))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 8)
        .frame(minHeight: settings.buttonSize.minTapSize)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

/// The lures that caught the most fish in this range and species filter.
struct StatsTopLuresSection: View {
    let lures: [StatsCalculator.LureCount]

    @Environment(AppSettings.self) private var settings
    @ScaledMetric(relativeTo: .headline) private var rankWidth: CGFloat = 24

    init(lures: [StatsCalculator.LureCount]) {
        self.lures = lures
    }

    var body: some View {
        StatsSectionCard("Top lures", footer: lures.isEmpty ? nil : "The same lure typed with different capitals counts once.") {
            if lures.isEmpty {
                Text("No lures logged for these fish. Open a catch and fill in Lure or bait to see what works.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(lures.enumerated()), id: \.element.id) { index, lure in
                        if index > 0 {
                            Divider()
                        }
                        row(rank: index + 1, lure: lure)
                    }
                }
            }
        }
    }

    private func row(rank: Int, lure: StatsCalculator.LureCount) -> some View {
        HStack(spacing: 12) {
            // The order already says the rank, so VoiceOver skips the number.
            Text("\(rank)")
                .font(.headline.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(minWidth: rankWidth, alignment: .leading)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(lure.name)
                    .font(.headline)
                    .fixedSize(horizontal: false, vertical: true)
                Text(StatsFormat.fishAndCatches(fish: lure.fish, catches: lure.catches))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
        .frame(minHeight: settings.buttonSize.minTapSize)
        .accessibilityElement(children: .combine)
    }
}
