import SwiftData
import SwiftUI

/// Which species the guide lists.
enum SpeciesGuideFilter: String, CaseIterable, Identifiable {
    case all, caught

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all: "All"
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

/// Species tab: the field guide, with your own tally next to each fish.
struct SpeciesGuideView: View {
    @Environment(AppSettings.self) private var settings
    @Query private var catches: [FishCatch]
    @State private var query = ""
    @State private var filter: SpeciesGuideFilter = .all
    @State private var showingIdentify = false

    var body: some View {
        let tally = caughtTally
        let sections = makeSections(tally: tally)
        NavigationStack {
            List {
                Section {
                    Picker("Show", selection: $filter) {
                        ForEach(SpeciesGuideFilter.allCases) { option in
                            Text(option.label).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                }

                if sections.isEmpty {
                    emptyState
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(sections) { section in
                        Section(section.title) {
                            ForEach(section.species) { species in
                                row(for: species, caught: tally[species.id] ?? 0)
                            }
                        }
                    }
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
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingIdentify = true
                    } label: {
                        Image(systemName: "camera")
                    }
                    .accessibilityLabel("Identify a fish")
                }
            }
            .sheet(isPresented: $showingIdentify) {
                IdentifyView()
            }
        }
    }

    // MARK: Rows

    private func row(for species: Species, caught: Int) -> some View {
        let isFavourite = settings.isFavourite(species.id)
        let favouriteTitle = isFavourite ? "Remove from favourites" : "Add to favourites"
        let favouriteSymbol = isFavourite ? "star.slash" : "star"
        return NavigationLink {
            SpeciesDetailView(species: species)
        } label: {
            SpeciesGuideRow(species: species, caughtCount: caught, isFavourite: isFavourite)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                toggleFavourite(species)
            } label: {
                Label(favouriteTitle, systemImage: favouriteSymbol)
            }
            .tint(.yellow)
        }
        .contextMenu {
            Button {
                toggleFavourite(species)
            } label: {
                Label(favouriteTitle, systemImage: favouriteSymbol)
            }
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            ContentUnavailableView.search(text: trimmed)
        } else {
            ContentUnavailableView(
                "No fish logged yet",
                systemImage: "fish",
                description: Text("Species you catch show up here. Switch to All to browse the whole guide.")
            )
        }
    }

    private func toggleFavourite(_ species: Species) {
        Haptics.tap()
        settings.toggleFavourite(species.id)
    }

    // MARK: Data

    /// Fish per species id, counting multi-fish entries.
    private var caughtTally: [String: Int] {
        var tally: [String: Int] = [:]
        for fishCatch in catches {
            tally[fishCatch.speciesID, default: 0] += fishCatch.count
        }
        return tally
    }

    private func shows(_ species: Species, tally: [String: Int]) -> Bool {
        filter == .all || (tally[species.id] ?? 0) > 0
    }

    private func makeSections(tally: [String: Int]) -> [SpeciesGuideSection] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            let results = SpeciesCatalog.search(trimmed).filter { shows($0, tally: tally) }
            if results.isEmpty { return [] }
            return [SpeciesGuideSection(id: "results", title: "Results", species: results)]
        }

        var sections: [SpeciesGuideSection] = []
        let favourites = settings.favouriteSpeciesIDs
            .filter { $0 != SpeciesCatalog.unknownID }
            .compactMap(SpeciesCatalog.species(id:))
            .filter { shows($0, tally: tally) }
        if !favourites.isEmpty {
            sections.append(SpeciesGuideSection(id: "favourites", title: "Favourites", species: favourites))
        }
        for entry in SpeciesCatalog.grouped {
            let members = entry.species.filter { shows($0, tally: tally) }
            if !members.isEmpty {
                sections.append(SpeciesGuideSection(id: entry.group.id, title: entry.group.label, species: members))
            }
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
