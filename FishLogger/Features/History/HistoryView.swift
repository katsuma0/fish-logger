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

/// Past fishing by day, as a list or a map. Search and filters apply to both.
struct HistoryView: View {
    @Environment(\.displayScale) private var displayScale
    @Query(sort: \Trip.startDate, order: .reverse) private var trips: [Trip]

    @State private var mode: HistoryDisplayMode = .list
    @State private var searchText = ""
    @State private var speciesFilter: String? = nil
    @State private var timeFilter: HistoryTimeFilter = .allTime
    @State private var selectedTrip: Trip? = nil
    /// Menus only draw plain images, so species icons are rendered once and reused.
    @State private var menuIcons: [String: UIImage] = [:]

    init() {}

    var body: some View {
        NavigationStack {
            screen
                .navigationTitle("Log")
                .searchable(
                    text: $searchText,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: "Spot or species"
                )
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        if !trips.isEmpty {
                            filterMenu
                        }
                    }
                }
                .sheet(item: $selectedTrip) { trip in
                    NavigationStack {
                        TripDetailView(trip: trip)
                            .toolbar {
                                ToolbarItem(placement: .cancellationAction) {
                                    Button("Close") { selectedTrip = nil }
                                }
                            }
                    }
                }
                .onAppear(perform: renderMenuIcons)
                .onChange(of: loggedSpeciesIDs) { renderMenuIcons() }
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
            let filtered = HistoryTripFilter.apply(
                trips,
                search: searchText,
                speciesID: speciesFilter,
                time: timeFilter
            )
            results(filtered)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.screenBackground)
                .safeAreaInset(edge: .top, spacing: 0) {
                    controls
                }
        }
    }

    @ViewBuilder
    private func results(_ filtered: [Trip]) -> some View {
        if filtered.isEmpty {
            noMatches
        } else {
            switch mode {
            case .list:
                HistoryTripList(trips: filtered)
            case .map:
                HistoryMapView(trips: filtered, speciesID: speciesFilter, onSelect: { trip in
                    selectedTrip = trip
                })
            }
        }
    }

    @ViewBuilder
    private var noMatches: some View {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !query.isEmpty && !hasActiveFilters {
            ContentUnavailableView.search(text: query)
        } else {
            ContentUnavailableView {
                Label("No matching trips", systemImage: "line.3.horizontal.decrease.circle")
            } description: {
                Text("Nothing in the log fits these filters. Clear them to see every trip.")
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
                if timeFilter != .allTime {
                    HistoryFilterChip(title: timeFilter.label, species: nil, systemImage: "calendar") {
                        timeFilter = .allTime
                    }
                }
            }
        }
    }

    // MARK: Filter menu

    private var filterMenu: some View {
        let species = loggedSpecies
        return Menu {
            Picker(selection: $speciesFilter) {
                Text("All species").tag(String?.none)
                ForEach(species) { item in
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

            Picker(selection: $timeFilter) {
                ForEach(HistoryTimeFilter.allCases) { filter in
                    Text(filter.label).tag(filter)
                }
            } label: {
                Label("Time", systemImage: "calendar")
            }
            .pickerStyle(.menu)

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
        if let image = menuIcons[species.id] {
            return Image(uiImage: image).renderingMode(.original)
        }
        return Image(systemName: "fish.fill")
    }

    // MARK: State helpers

    private var hasActiveFilters: Bool {
        speciesFilter != nil || timeFilter != .allTime
    }

    private var filterSummary: String {
        var parts: [String] = []
        if let speciesID = speciesFilter {
            parts.append(SpeciesCatalog.species(id: speciesID)?.commonName ?? "Unknown fish")
        }
        if timeFilter != .allTime {
            parts.append(timeFilter.label)
        }
        return parts.isEmpty ? "No filters" : parts.joined(separator: ", ")
    }

    private var loggedSpecies: [Species] {
        HistoryTripFilter.loggedSpecies(in: trips)
    }

    private var loggedSpeciesIDs: [String] {
        loggedSpecies.map(\.id)
    }

    private func clearFilters() {
        speciesFilter = nil
        timeFilter = .allTime
    }

    private func renderMenuIcons() {
        var icons = menuIcons
        var changed = false
        for species in loggedSpecies where icons[species.id] == nil {
            let renderer = ImageRenderer(content: SpeciesIcon(species: species, size: 22))
            renderer.scale = displayScale
            if let image = renderer.uiImage {
                icons[species.id] = image.withRenderingMode(.alwaysOriginal)
                changed = true
            }
        }
        if changed {
            menuIcons = icons
        }
    }
}

/// Removable capsule for an active filter. The whole chip is the remove button.
private struct HistoryFilterChip: View {
    let title: String
    let species: Species?
    let systemImage: String?
    let onRemove: () -> Void

    @Environment(AppSettings.self) private var settings

    init(title: String, species: Species?, systemImage: String?, onRemove: @escaping () -> Void) {
        self.title = title
        self.species = species
        self.systemImage = systemImage
        self.onRemove = onRemove
    }

    var body: some View {
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
                    .lineLimit(1)
                Image(systemName: "xmark.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.leading, 8)
            .padding(.trailing, 10)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(Color.accentColor.opacity(settings.highContrast ? 0.3 : 0.15))
            )
            .overlay(
                Capsule().strokeBorder(
                    settings.highContrast ? Color.primary : Color.clear,
                    lineWidth: settings.highContrast ? 1.5 : 0
                )
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
