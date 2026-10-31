import SwiftData
import SwiftUI

/// Stats tab root. Everything is worked out once per render by `StatsCalculator` and handed down.
struct StatsView: View {
    @Environment(AppSettings.self) private var settings
    @Query(sort: \Trip.startDate, order: .reverse) private var allTrips: [Trip]

    @State private var range: StatsRange = .allTime
    @State private var speciesFilter: String? = nil

    init() {}

    var body: some View {
        let stats = StatsCalculator(trips: allTrips, range: range, speciesID: speciesFilter)
        let loggedSpecies = StatsCalculator.loggedSpeciesIDs(in: allTrips)

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Picker("Range", selection: $range) {
                        ForEach(StatsRange.allCases) { option in
                            Text(option.label).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)

                    if let speciesFilter {
                        filterBanner(for: speciesFilter)
                    }

                    if stats.catches.isEmpty {
                        emptyState(tripCount: stats.tripCount)
                    } else {
                        StatsSummaryGrid(stats: stats)
                        if speciesFilter == nil {
                            StatsSpeciesChart(items: stats.bySpecies)
                        }
                        StatsHourChart(items: stats.byHourOfDay)
                        StatsMonthChart(items: stats.byMonth)
                        StatsSizeChart(items: stats.sizeClassCounts)
                        StatsConditionsSection(stats: stats)
                        if !stats.personalBests.isEmpty {
                            StatsPersonalBestsSection(bests: stats.personalBests)
                        }
                        if !stats.topSpots.isEmpty {
                            StatsTopSpotsSection(spots: stats.topSpots)
                        }
                    }
                }
                .padding()
            }
            .background(Theme.screenBackground)
            .navigationTitle("Stats")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    speciesMenu(loggedSpecies)
                }
            }
        }
    }

    private func speciesMenu(_ speciesIDs: [String]) -> some View {
        Menu {
            Picker("Species", selection: $speciesFilter) {
                Text("All species").tag(String?.none)
                ForEach(speciesIDs, id: \.self) { speciesID in
                    Text(StatsCalculator.speciesName(for: speciesID)).tag(String?.some(speciesID))
                }
            }
        } label: {
            Label(
                "Species",
                systemImage: speciesFilter == nil
                    ? "line.3.horizontal.decrease.circle"
                    : "line.3.horizontal.decrease.circle.fill"
            )
        }
        .accessibilityLabel("Filter by species")
        .accessibilityValue(filterName)
    }

    private var filterName: String {
        guard let speciesFilter else { return "All species" }
        return StatsCalculator.speciesName(for: speciesFilter)
    }

    private func filterBanner(for speciesID: String) -> some View {
        HStack(spacing: 12) {
            SpeciesIcon(species: SpeciesCatalog.species(id: speciesID), size: 28)
            Text("Showing \(StatsCalculator.speciesName(for: speciesID)) only")
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 8)
            Button("Show all") {
                speciesFilter = nil
            }
            .frame(minHeight: settings.buttonSize.minTapSize)
        }
        .padding(.horizontal, 12)
        .cardBackground()
    }

    private func emptyState(tripCount: Int) -> some View {
        ContentUnavailableView(
            "No fish in this range yet.",
            systemImage: "chart.bar.xaxis",
            description: Text(emptyHint(tripCount: tripCount))
        )
        .frame(maxWidth: .infinity)
        .padding(.top, 32)
    }

    private func emptyHint(tripCount: Int) -> String {
        if allTrips.isEmpty {
            return "Start a trip from the Today tab and tap a species for each fish."
        }
        if speciesFilter != nil {
            return "Pick All species or a wider range."
        }
        if tripCount > 0 {
            return "\(StatsFormat.trips(tripCount)) in this range with no fish logged. Pick a wider range to see more."
        }
        return "Pick a wider range, or log a catch from the Today tab."
    }
}

#Preview {
    StatsView()
        .modelContainer(AppModelContainer.inMemory())
        .environment(AppSettings.shared)
}
