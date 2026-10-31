import SwiftData
import SwiftUI

/// Which species the guide lists.
enum SpeciesGuideFilter: String, CaseIterable, Identifiable {
    case myRegions, all, caught

    var id: String { rawValue }

    var label: String {
        switch self {
        case .myRegions: "My regions"
        case .all: "All species"
        case .caught: "Caught by me"
        }
    }
}

/// One list section, built once per render so rows do not regroup the catalog.
private struct SpeciesGuideSection: Identifiable {
    let id: String
    let title: String
    let species: [Species]
}

/// Species tab: the field guide, with your own tally next to each fish. Opens on the fish of your
/// regions when you have picked some, with All species one tap away.
struct SpeciesGuideView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    /// Fish per species id. Filled on appear from a two-field fetch rather than a live query, so
    /// typing in search, or logging on another tab, never walks the whole log here.
    @State private var tally: [String: Int] = [:]
    @State private var query = ""
    /// Nil until the person picks one, so the default follows their regions.
    @State private var pickedFilter: SpeciesGuideFilter?
    @State private var showingIdentify = false
    /// A catch logged through Photo ID from this tab, shown in the toast with Undo.
    @State private var loggedCatch: FishCatch?

    var body: some View {
        // Read once per render and passed down, so rows never go back to settings.
        let homeRegions = settings.homeRegions
        let filter = effectiveFilter(homeRegions: homeRegions)
        let favouriteIDs = settings.favouriteSpeciesIDs
        let favouriteSet = Set(favouriteIDs)
        let sections = makeSections(filter: filter, homeRegions: homeRegions, favouriteIDs: favouriteIDs)
        let isSearching = !trimmedQuery.isEmpty
        NavigationStack {
            List {
                filterSection(filter: filter, homeRegions: homeRegions)

                if sections.isEmpty {
                    emptyState(filter: filter)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(sections) { section in
                        Section(section.title) {
                            ForEach(section.species) { species in
                                row(
                                    for: species,
                                    caught: tally[species.id] ?? 0,
                                    isFavourite: favouriteSet.contains(species.id)
                                )
                            }
                        }
                    }
                }

                if filter == .myRegions, !isSearching {
                    showAllSection
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Species")
            .searchable(
                text: $query,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Walleye, pickerel, Esox"
            )
            .toolbar {
                // On the thumb side, same as the camera on Today.
                ToolbarItem(placement: settings.leftHanded ? ToolbarItemPlacement.topBarLeading : ToolbarItemPlacement.topBarTrailing) {
                    Button {
                        showingIdentify = true
                    } label: {
                        Label("Photo ID", systemImage: "camera")
                    }
                    .accessibilityHint("Take or pick a photo and get a species suggestion")
                }
            }
            .sheet(isPresented: $showingIdentify) {
                IdentifyView(onLogged: { fishCatch in
                    loggedCatch = fishCatch
                })
            }
            // Also runs when a species page is popped, where a fish may just have been logged.
            .onAppear { refreshTally() }
            // A catch from Photo ID adds to the tally; Undo in the toast takes it away again.
            .onChange(of: loggedCatch == nil) { refreshTally() }
            .loggedToast($loggedCatch)
        }
    }

    // MARK: Filter

    @ViewBuilder
    private func filterSection(filter: SpeciesGuideFilter, homeRegions: Set<FishingRegion>) -> some View {
        // With no regions picked, My regions would be the same list as All species.
        let options = homeRegions.isEmpty
            ? SpeciesGuideFilter.allCases.filter { $0 != .myRegions }
            : SpeciesGuideFilter.allCases
        let selection = Binding<SpeciesGuideFilter>(
            get: { filter },
            set: { pickedFilter = $0 }
        )
        Section {
            if dynamicTypeSize.isAccessibilitySize {
                // Three segments cannot fit large text, so it becomes a menu row with its label.
                Picker("Show", selection: selection) {
                    ForEach(options) { option in
                        Text(option.label).tag(option)
                    }
                }
                .pickerStyle(.menu)
                .frame(minHeight: settings.buttonSize.minTapSize)
            } else {
                Picker("Show", selection: selection) {
                    ForEach(options) { option in
                        Text(option.label).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
            }
        }
    }

    /// The person's pick, or My regions when they have regions and All species when they do not.
    private func effectiveFilter(homeRegions: Set<FishingRegion>) -> SpeciesGuideFilter {
        let wanted: SpeciesGuideFilter = pickedFilter ?? (homeRegions.isEmpty ? .all : .myRegions)
        return wanted == .myRegions && homeRegions.isEmpty ? .all : wanted
    }

    /// The way out of the regional list, at the bottom where the list runs out.
    private var showAllSection: some View {
        Section {
            Button {
                pickedFilter = .all
            } label: {
                Label("Show all species", systemImage: "globe.americas")
                    .frame(maxWidth: .infinity, minHeight: settings.buttonSize.minTapSize, alignment: .leading)
                    .contentShape(Rectangle())
            }
        } footer: {
            Text("Your regions: \(settings.homeRegionsSummary). Change them in Settings.")
        }
    }

    // MARK: Rows

    private func row(for species: Species, caught: Int, isFavourite: Bool) -> some View {
        let favouriteTitle = isFavourite ? "Remove from favourites" : "Add to favourites"
        let favouriteSymbol = isFavourite ? "star.slash" : "star"
        return NavigationLink {
            SpeciesDetailView(species: species)
        } label: {
            SpeciesGuideRow(species: species, caughtCount: caught, isFavourite: isFavourite)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                settings.toggleFavourite(species.id)
            } label: {
                Label(favouriteTitle, systemImage: favouriteSymbol)
            }
            .tint(.yellow)
        }
        .contextMenu {
            Button {
                settings.toggleFavourite(species.id)
            } label: {
                Label(favouriteTitle, systemImage: favouriteSymbol)
            }
        }
    }

    @ViewBuilder
    private func emptyState(filter: SpeciesGuideFilter) -> some View {
        let trimmed = trimmedQuery
        if !trimmed.isEmpty {
            ContentUnavailableView.search(text: trimmed)
        } else if filter == .caught {
            ContentUnavailableView(
                "No fish logged yet",
                systemImage: "fish",
                description: Text("Species you catch show up here. Switch to All species to browse the whole guide.")
            )
        } else {
            ContentUnavailableView(
                "No species to show",
                systemImage: "book",
                description: Text("Switch to All species to browse the whole guide.")
            )
        }
    }

    // MARK: Data

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Fish per species id, counting multi-fish entries. Two fields per catch, so a long log does not
    /// pull notes, conditions, or photos into memory.
    private func refreshTally() {
        var descriptor = FetchDescriptor<FishCatch>()
        descriptor.propertiesToFetch = [\.speciesID, \.count]
        let catches = (try? modelContext.fetch(descriptor)) ?? []
        var counts: [String: Int] = [:]
        for fishCatch in catches {
            counts[fishCatch.speciesID, default: 0] += fishCatch.count
        }
        if counts != tally { tally = counts }
    }

    private func makeSections(
        filter: SpeciesGuideFilter,
        homeRegions: Set<FishingRegion>,
        favouriteIDs: [String]
    ) -> [SpeciesGuideSection] {
        let tally = self.tally
        let trimmed = trimmedQuery
        if !trimmed.isEmpty {
            let results = SpeciesCatalog.search(trimmed)
            switch filter {
            case .all:
                return results.isEmpty ? [] : [SpeciesGuideSection(id: "results", title: "Results", species: results)]
            case .caught:
                let caught = results.filter { (tally[$0.id] ?? 0) > 0 }
                return caught.isEmpty ? [] : [SpeciesGuideSection(id: "results", title: "Results", species: caught)]
            case .myRegions:
                // Search still reaches every fish, so an odd catch can be looked up. Local fish come first.
                let local = results.filter { $0.lives(in: homeRegions) }
                let elsewhere = results.filter { !$0.lives(in: homeRegions) }
                var sections: [SpeciesGuideSection] = []
                if !local.isEmpty {
                    sections.append(SpeciesGuideSection(id: "results", title: "Results", species: local))
                }
                if !elsewhere.isEmpty {
                    sections.append(SpeciesGuideSection(id: "elsewhere", title: "Other regions", species: elsewhere))
                }
                return sections
            }
        }

        // Grouped lists come from the catalog, which caches them per region set.
        let groups: [(group: SpeciesGroup, species: [Species])]
        let favouriteFilter: (Species) -> Bool
        switch filter {
        case .myRegions:
            groups = SpeciesCatalog.grouped(in: homeRegions)
            // Favourites were picked by hand, so they show even from outside the regions.
            favouriteFilter = { _ in true }
        case .all:
            groups = SpeciesCatalog.grouped
            favouriteFilter = { _ in true }
        case .caught:
            groups = SpeciesCatalog.grouped.compactMap { entry -> (group: SpeciesGroup, species: [Species])? in
                let members = entry.species.filter { (tally[$0.id] ?? 0) > 0 }
                return members.isEmpty ? nil : (group: entry.group, species: members)
            }
            favouriteFilter = { (tally[$0.id] ?? 0) > 0 }
        }

        var sections: [SpeciesGuideSection] = []
        let favourites = favouriteIDs
            .filter { $0 != SpeciesCatalog.unknownID }
            .compactMap(SpeciesCatalog.species(id:))
            .filter(favouriteFilter)
        if !favourites.isEmpty {
            sections.append(SpeciesGuideSection(id: "favourites", title: "Favourites", species: favourites))
        }
        for entry in groups {
            sections.append(SpeciesGuideSection(id: entry.group.id, title: entry.group.label, species: entry.species))
        }
        return sections
    }
}

/// Row content for one species. The NavigationLink around it lives in the list.
private struct SpeciesGuideRow: View {
    let species: Species
    let caughtCount: Int
    let isFavourite: Bool

    @Environment(AppSettings.self) private var settings

    init(species: Species, caughtCount: Int, isFavourite: Bool) {
        self.species = species
        self.caughtCount = caughtCount
        self.isFavourite = isFavourite
    }

    var body: some View {
        HStack(spacing: 12) {
            SpeciesIcon(species: species, size: settings.buttonSize.iconSize + 10)

            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(species.commonName)
                        .font(.body)
                        .foregroundStyle(.primary)
                    if isFavourite {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                            .accessibilityLabel("Favourite")
                    }
                }
                if !species.scientificName.isEmpty {
                    Text(species.scientificName)
                        .font(.caption)
                        .italic()
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 8)

            if caughtCount > 0 {
                Text("\(caughtCount) caught")
                    .font(.subheadline)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
        }
        .frame(minHeight: settings.buttonSize.minTapSize)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    SpeciesGuideView()
        .modelContainer(AppModelContainer.inMemory())
        .environment(AppSettings.shared)
}
