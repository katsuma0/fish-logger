import SwiftUI

/// Biggest fish per species. Each row opens the species guide page.
struct StatsPersonalBestsSection: View {
    let bests: [StatsCalculator.PersonalBest]

    init(bests: [StatsCalculator.PersonalBest]) {
        self.bests = bests
    }

    var body: some View {
        StatsSectionCard("Personal bests", footer: "Longest and heaviest come from measured fish only.") {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(bests) { best in
                    if best.id != bests.first?.id {
                        Divider()
                    }
                    if let species = best.species {
                        NavigationLink(destination: SpeciesDetailView(species: species)) {
                            StatsPersonalBestRow(best: best, species: species, showsChevron: true)
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("Opens the species guide.")
                    } else {
                        StatsPersonalBestRow(best: best, species: nil, showsChevron: false)
                    }
                }
            }
        }
    }
}

private struct StatsPersonalBestRow: View {
    let best: StatsCalculator.PersonalBest
    let species: Species?
    let showsChevron: Bool

    @Environment(AppSettings.self) private var settings

    init(best: StatsCalculator.PersonalBest, species: Species?, showsChevron: Bool) {
        self.best = best
        self.species = species
        self.showsChevron = showsChevron
    }

    var body: some View {
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

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
        }
        .padding(.vertical, 8)
        .frame(minHeight: settings.buttonSize.minTapSize)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private var detailLines: [String] {
        var lines: [String] = []
        if let longest = best.longestCm {
            var line = "Longest \(settings.length(longest))"
            if let date = best.longestCatchDate {
                line += " on \(date.formatted(date: .abbreviated, time: .omitted))"
            }
            lines.append(line)
        }
        if let heaviest = best.heaviestKg {
            lines.append("Heaviest \(settings.weight(heaviest))")
        }
        if let biggest = best.biggestClass {
            lines.append("Biggest: \(biggest.label)")
        }
        if lines.isEmpty {
            lines.append("No size logged yet")
        }
        return lines
    }
}

/// Where the fish came from, most fish first.
struct StatsTopSpotsSection: View {
    let spots: [StatsCalculator.SpotCount]

    @Environment(AppSettings.self) private var settings

    init(spots: [StatsCalculator.SpotCount]) {
        self.spots = spots
    }

    var body: some View {
        StatsSectionCard("Top spots") {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(spots) { spot in
                    if spot.id != spots.first?.id {
                        Divider()
                    }
                    HStack(spacing: 12) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .frame(width: settings.buttonSize.iconSize)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(spot.name)
                                .font(.headline)
                            Text("\(StatsFormat.fish(spot.fish)), \(StatsFormat.trips(spot.trips))")
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
        }
    }
}
