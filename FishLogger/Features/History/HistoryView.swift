import SwiftData
import SwiftUI
import UIKit

private enum HistoryDisplayMode: String, CaseIterable, Identifiable {
    case list, map

    var id: String { rawValue }

    var label: String {
        switch self {
        case .list: "List"
        case .map: "Map"
        }
    }
}

/// Everything the filter pass depends on. A change starts a new pass in `.task(id:)`.
private struct HistoryFilterKey: Equatable {
    let search: String
    let speciesID: String?
    let time: HistoryTimeFilter
    let day: Date?
    let tripCount: Int
    let dataVersion: Int
}

/// Which state of the log a cached result was built from.
private struct HistoryDataToken: Equatable {
    let tripCount: Int
    let dataVersion: Int
}

/// The trips the last filter pass let through.
private struct HistoryResults {
    let trips: [Trip]
    /// How many trips the log held for this pass. A different count now means one was added or deleted.
    let tripCount: Int
    /// Goes up whenever the trips or their data change, so the map knows to rebuild its pins.
    let version: Int
}

/// Bookkeeping between filter passes. A class, so updating it never redraws the screen.
private final class HistoryFilterCache {
    var searchIndex = HistorySearchIndex()
    var indexToken: HistoryDataToken? = nil
    var speciesToken: HistoryDataToken? = nil
    var resultsToken: HistoryDataToken? = nil
    var appliedQuery = ""
    var hasAppeared = false
}

/// Species icons for the filter menu, which can only draw plain images. Each one is rendered the first
/// time a species needs it and kept for the life of the app, so switching tabs never redraws them.
@MainActor
private enum HistoryMenuIcons {
    private static var images: [String: UIImage] = [:]

    static func image(for species: Species, scale: CGFloat) -> UIImage? {
        images[cacheKey(species.id, scale)]
    }

    static func prepare(_ species: [Species], scale: CGFloat) {
        for item in species {
            let itemKey = cacheKey(item.id, scale)
            guard images[itemKey] == nil else { continue }
            let renderer = ImageRenderer(content: SpeciesIcon(species: item, size: 22))
            renderer.scale = scale
            if let image = renderer.uiImage {
                images[itemKey] = image.withRenderingMode(.alwaysOriginal)
            }
        }
    }

    private static func cacheKey(_ id: String, _ scale: CGFloat) -> String { "\(id)@\(scale)" }
}

/// Past fishing by day, as a list or a map. Search and filters apply to both.
///
/// Filtering never runs in `body`. A pass in `.task(id:)` works out the matching trips and the species
/// for the filter menu, waiting 200 ms after each keystroke so typing stays ahead of the work.
struct HistoryView: View {
    @Environment(\.displayScale) private var displayScale
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Trip.startDate, order: .reverse) private var trips: [Trip]

    @State private var mode: HistoryDisplayMode = .list
    @State private var searchText = ""
    @State private var speciesFilter: String? = nil
    @State private var timeFilter: HistoryTimeFilter = .allTime
    /// Start of a day picked from the calendar. A picked day and a time range replace each other.
    @State private var dayFilter: Date? = nil
    @State private var showingDayPicker = false
    /// A trip opened from the map. Pushed, the same as a trip opened from the list.
    @State private var selectedTrip: Trip? = nil
    @State private var results: HistoryResults? = nil
    /// Species anywhere in the log, for the filter menu.
    @State private var loggedSpecies: [Species] = []
    /// Goes up each time the screen comes back from a trip or another tab, since catches may have been
    /// added or changed there.
    @State private var dataVersion = 0
    @State private var cache = HistoryFilterCache()

    init() {}

    var body: some View {
        NavigationStack {
            screen
                .navigationTitle("Trips")
                .searchable(
                    text: $searchText,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: "Spot, species or day"
                )
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        if !trips.isEmpty {
                            filterMenu
                        }
                    }
                }
                .navigationDestination(item: $selectedTrip) { trip in
                    TripDetailView(trip: trip)
                }
                .sheet(isPresented: $showingDayPicker) {
                    HistoryDayPickerSheet(
                        trips: trips,
                        initialDay: dayFilter ?? trips.first?.startDate ?? .now,
                        onPick: pickDay
                    )
                }
                .task(id: filterKey) {
                    await refreshResults(for: filterKey)
                }
                .onAppear(perform: noteAppeared)
        }
    }

    // MARK: Content

    @ViewBuilder
    private var screen: some View {
        if trips.isEmpty {
            ContentUnavailableView(
                "No trips yet",
                systemImage: "fish",
                description: Text("Start one from the Today tab.")
            )
        } else {
            resultsView(shownTrips)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.screenBackground)
                .safeAreaInset(edge: .top, spacing: 0) {
                    controls
                }
        }
    }

    @ViewBuilder
    private func resultsView(_ shown: [Trip]) -> some View {
        if shown.isEmpty {
            noMatches
        } else {
            switch mode {
            case .list:
                HistoryTripList(trips: shown)
            case .map:
                HistoryMapView(
                    trips: shown,
                    speciesID: speciesFilter,
                    contentVersion: results?.version ?? 0,
                    fitKey: HistoryMapFitKey(speciesID: speciesFilter, time: timeFilter, day: dayFilter),
                    onSelect: { trip in
                        selectedTrip = trip
                    }
                )
            }
        }
    }

    /// No filters and no search is the usual case and needs no work at all. Otherwise this is the last
    /// pass, which stays on screen while the next one waits out the typing.
    private var shownTrips: [Trip] {
        if !hasActiveFilters && trimmedSearch.isEmpty { return trips }
        guard let results else { return trips }
        if results.tripCount == trips.count { return results.trips }
        // A trip was deleted since that pass. Leave it out until the next pass lands, because reading a
        // deleted trip can crash.
        return results.trips.filter { !$0.historyIsGone }
    }

    @ViewBuilder
    private var noMatches: some View {
        let query = trimmedSearch
        if !query.isEmpty && !hasActiveFilters {
            ContentUnavailableView.search(text: query)
        } else {
            ContentUnavailableView {
                Label("No matching trips", systemImage: "line.3.horizontal.decrease.circle")
            } description: {
                Text("No trips fit these filters. Clear them to see every trip.")
            } actions: {
                Button("Clear filters") { clearFilters() }
                    .buttonStyle(.borderedProminent)
            }
        }
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 4) {
            Picker("Show", selection: $mode) {
                ForEach(HistoryDisplayMode.allCases) { option in
                    Text(option.label).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .padding(.top, 4)

            if hasActiveFilters {
                filterChips
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, hasActiveFilters ? 0 : 8)
        .background(Theme.screenBackground)
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if let speciesID = speciesFilter {
                    let species = SpeciesCatalog.species(id: speciesID)
                    HistoryFilterChip(
                        title: species?.commonName ?? "Unknown fish",
                        species: species ?? SpeciesCatalog.unknown,
                        systemImage: nil
                    ) {
                        speciesFilter = nil
                    }
                }
                if let day = dayFilter {
                    HistoryFilterChip(title: HistoryText.dayTitle(day), species: nil, systemImage: "calendar") {
                        dayFilter = nil
                    }
                } else if timeFilter != .allTime {
                    HistoryFilterChip(title: timeFilter.label, species: nil, systemImage: "calendar") {
                        timeFilter = .allTime
                    }
                }
            }
        }
    }

    // MARK: Filter menu

    private var filterMenu: some View {
        Menu {
            Picker(selection: $speciesFilter) {
                Text("All species").tag(String?.none)
                ForEach(loggedSpecies) { item in
                    Label {
                        Text(item.commonName)
                    } icon: {
                        menuIcon(for: item)
                    }
                    .tag(Optional(item.id))
                }
            } label: {
                Label("Species", systemImage: "fish")
            }
            .pickerStyle(.menu)

            Picker(selection: timeSelection) {
                ForEach(HistoryTimeFilter.allCases) { filter in
                    Text(filter.label).tag(Optional(filter))
                }
                // A picked day shows here as the current choice, so the menu never claims "All time".
                if let day = dayFilter {
                    Text(HistoryText.dayTitle(day)).tag(HistoryTimeFilter?.none)
                }
            } label: {
                Label("Time", systemImage: "calendar")
            }
            .pickerStyle(.menu)

            Button {
                showingDayPicker = true
            } label: {
                Label("Pick a day", systemImage: "calendar.circle")
            }

            if hasActiveFilters {
                Divider()
                Button {
                    clearFilters()
                } label: {
                    Label("Clear filters", systemImage: "xmark.circle")
                }
            }
        } label: {
            Label(
                "Filter",
                systemImage: hasActiveFilters
                    ? "line.3.horizontal.decrease.circle.fill"
                    : "line.3.horizontal.decrease.circle"
            )
        }
        .accessibilityValue(filterSummary)
    }

    private func menuIcon(for species: Species) -> Image {
        if let image = HistoryMenuIcons.image(for: species, scale: displayScale) {
            return Image(uiImage: image).renderingMode(.original)
        }
        return Image(systemName: "fish.fill")
    }

    /// The time picker reads nil while a day is picked. Choosing a range clears the day.
    private var timeSelection: Binding<HistoryTimeFilter?> {
        Binding(
            get: { dayFilter == nil ? timeFilter : nil },
            set: { newValue in
                guard let newValue else { return }
                timeFilter = newValue
                dayFilter = nil
            }
        )
    }

    // MARK: State helpers

    private var trimmedSearch: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var hasActiveFilters: Bool {
        speciesFilter != nil || timeFilter != .allTime || dayFilter != nil
    }

    private var filterSummary: String {
        var parts: [String] = []
        if let speciesID = speciesFilter {
            parts.append(SpeciesCatalog.species(id: speciesID)?.commonName ?? "Unknown fish")
        }
        if let day = dayFilter {
            parts.append(HistoryText.dayTitle(day))
        } else if timeFilter != .allTime {
            parts.append(timeFilter.label)
        }
        return parts.isEmpty ? "No filters" : parts.joined(separator: ", ")
    }

    private var filterKey: HistoryFilterKey {
        HistoryFilterKey(
            search: searchText,
            speciesID: speciesFilter,
            time: timeFilter,
            day: dayFilter,
            tripCount: trips.count,
            dataVersion: dataVersion
        )
    }

    private func clearFilters() {
        speciesFilter = nil
        timeFilter = .allTime
        dayFilter = nil
    }

    private func pickDay(_ day: Date) {
        dayFilter = Calendar.current.startOfDay(for: day)
        timeFilter = .allTime
    }

    /// The first appearance is covered by the first pass. Later ones mean the person is back from a
    /// trip's page or another tab, where catches may have changed, so the next pass reads fresh data.
    private func noteAppeared() {
        if cache.hasAppeared {
            dataVersion &+= 1
        } else {
            cache.hasAppeared = true
        }
    }

    // MARK: Filter pass

    private func refreshResults(for key: HistoryFilterKey) async {
        let query = HistoryText.folded(key.search.trimmingCharacters(in: .whitespacesAndNewlines))
        // Typing waits for a pause. Filter taps, clearing the search, and new data apply at once.
        if !query.isEmpty, query != cache.appliedQuery {
            do {
                try await Task.sleep(for: .milliseconds(200))
            } catch {
                return
            }
        }

        let data = HistoryDataToken(tripCount: key.tripCount, dataVersion: key.dataVersion)
        let current = trips

        if cache.speciesToken != data {
            let species = HistoryTripFilter.loggedSpecies(in: modelContext)
            // Icons first, so the menu has them by the time it redraws with the new list.
            HistoryMenuIcons.prepare(species, scale: displayScale)
            cache.speciesToken = data
            if species != loggedSpecies {
                loggedSpecies = species
            }
        }

        // The index is only worth building once someone searches or picks a species.
        let needsIndex = !query.isEmpty || key.speciesID != nil
        if needsIndex, cache.indexToken != data {
            cache.searchIndex = HistoryTripFilter.searchIndex(for: current)
            cache.indexToken = data
        }

        let filtered = HistoryTripFilter.apply(
            current,
            search: key.search,
            speciesID: key.speciesID,
            time: key.time,
            day: key.day,
            index: needsIndex ? cache.searchIndex : nil
        )
        cache.appliedQuery = query

        let previous = results
        let sameTrips = previous.map { old in
            old.trips.count == filtered.count && old.trips.elementsEqual(filtered) { $0 === $1 }
        } ?? false
        if sameTrips, previous?.tripCount == current.count, cache.resultsToken == data {
            return
        }
        results = HistoryResults(
            trips: filtered,
            tripCount: current.count,
            version: (previous?.version ?? 0) &+ 1
        )
        cache.resultsToken = data
    }
}

/// Removable capsule for an active filter. The whole chip is the remove button.
private struct HistoryFilterChip: View {
    let title: String
    let species: Species?
    let systemImage: String?
    let onRemove: () -> Void

    @Environment(AppSettings.self) private var settings
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    init(title: String, species: Species?, systemImage: String?, onRemove: @escaping () -> Void) {
        self.title = title
        self.species = species
        self.systemImage = systemImage
        self.onRemove = onRemove
    }

    var body: some View {
        let strong = settings.usesStrongContrast(colorSchemeContrast)
        Button(action: onRemove) {
            HStack(spacing: 6) {
                if let species {
                    SpeciesIcon(species: species, size: 18)
                } else if let systemImage {
                    Image(systemName: systemImage)
                        .font(.caption)
                }
                Text(title)
                    .font(.subheadline.weight(.medium))
                Image(systemName: "xmark.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.leading, 8)
            .padding(.trailing, 10)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(Color.accentColor.opacity(strong ? 0.3 : 0.15))
            )
            .overlay(
                Capsule().strokeBorder(strong ? Color.primary : Color.clear, lineWidth: strong ? 1.5 : 0)
            )
            .frame(minHeight: settings.buttonSize.minTapSize)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(spokenLabel)
    }

    private var spokenLabel: String { "Remove filter: \(title)" }
}

#Preview {
    HistoryView()
        .modelContainer(AppModelContainer.inMemory())
        .environment(AppSettings.shared)
}
