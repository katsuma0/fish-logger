import SwiftData
import SwiftUI

/// The trips behind one Top spots row, newest first. Each row opens the trip's page, so
/// "show me my trips at this spot" is one tap from Stats.
struct StatsSpotTripsView: View {
    let spot: StatsCalculator.SpotCount
    /// The Stats range these trips come from, for example "Last 30 days".
    let scopeLabel: String

    @Environment(\.modelContext) private var modelContext
    @State private var trips: [Trip] = []
    @State private var didLoad = false

    init(spot: StatsCalculator.SpotCount, scopeLabel: String) {
        self.spot = spot
        self.scopeLabel = scopeLabel
    }

    var body: some View {
        // A trip deleted from its page is still in the array until the next load, and reading a
        // deleted model can crash, so those are dropped first.
        let live = trips.filter { !$0.isDeleted && $0.modelContext != nil }

        List {
            Section {
                ForEach(live) { trip in
                    NavigationLink {
                        TripDetailView(trip: trip)
                    } label: {
                        StatsSpotTripRow(trip: trip)
                    }
                }
            } header: {
                Text(scopeLabel)
            }
        }
        .listStyle(.insetGrouped)
        .overlay {
            if didLoad && live.isEmpty {
                ContentUnavailableView(
                    "No trips here",
                    systemImage: "mappin.slash",
                    description: Text("These trips are no longer in the log.")
                )
            }
        }
        .navigationTitle(spot.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: load)
    }

    /// Fetches only this spot's trips by id. Runs again on the way back from a trip's page, so
    /// a trip deleted there drops off the list.
    private func load() {
        let ids = spot.tripIDs
        let descriptor = FetchDescriptor<Trip>(
            predicate: #Predicate<Trip> { ids.contains($0.id) },
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        trips = (try? modelContext.fetch(descriptor)) ?? []
        didLoad = true
    }
}

private struct StatsSpotTripRow: View {
    let trip: Trip

    @Environment(AppSettings.self) private var settings

    init(trip: Trip) {
        self.trip = trip
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(dayText)
                .font(.headline)
            Text(detailText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 4)
        .frame(minHeight: settings.buttonSize.minTapSize, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    /// "Sat, Oct 26, 2024".
    private var dayText: String {
        trip.startDate.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day().year())
    }

    /// "6:10 AM, 4 fish", with "running now" added for the active trip.
    private var detailText: String {
        let start = trip.startDate.formatted(date: .omitted, time: .shortened)
        let fish = StatsFormat.fish(trip.totalFish)
        return trip.isActive ? "Started \(start), running now, \(fish)" : "\(start), \(fish)"
    }
}
