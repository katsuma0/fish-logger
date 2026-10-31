import SwiftUI

/// Pinned species for the quick log grid. Favourites sit on top in grid order; the fish of your
/// regions are below, grouped like the species guide, with a star to pin them and a way to show
/// every species.
struct SettingsFavouritesView: View {
    @Environment(AppSettings.self) private var settings
    @State private var showsAllRegions = false

    var body: some View {
        let homeRegions = settings.homeRegions
        List {
            Section {
                if favourites.isEmpty {
                    Text("No favourites yet. Tap a species below to pin it.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(favourites) { species in
                        favouriteRow(species)
                    }
                    .onMove(perform: move)
                    .onDelete(perform: remove)
                }
            } header: {
                Text("Favourites")
            } footer: {
                Text("These show first in the quick log grid, in this order. Tap Edit to reorder or remove.")
            }

            ForEach(otherGroups(regions: showsAllRegions ? [] : homeRegions)) { group in
                Section(group.title) {
                    ForEach(group.species) { species in
                        addRow(species)
                    }
                }
            }

            if !homeRegions.isEmpty {
                Section {
                    Button {
                        // No animation: diffing dozens of rows would stutter, and the list jumps anyway.
                        showsAllRegions.toggle()
                    } label: {
                        Label(
                            showsAllRegions ? "Only show my regions" : "Show fish from other regions",
                            systemImage: showsAllRegions ? "mappin.and.ellipse" : "globe.americas"
                        )
                        .frame(minHeight: settings.buttonSize.minTapSize)
                    }
                } footer: {
                    Text("Your regions: \(settings.homeRegionsSummary). Change them in Settings.")
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Favourite species")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }
        }
    }

    private func favouriteRow(_ species: Species) -> some View {
        HStack(spacing: 12) {
            SpeciesIcon(species: species, size: 32)
            Text(species.commonName)
            Spacer(minLength: 8)
            Image(systemName: "star.fill")
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
        }
        .frame(minHeight: settings.buttonSize.minTapSize)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(species.commonName), favourite")
        .accessibilityAction(named: Text("Remove from favourites")) {
            settings.toggleFavourite(species.id)
        }
    }

    /// No haptic: the row moving up into Favourites is the feedback.
    private func addRow(_ species: Species) -> some View {
        Button {
            settings.toggleFavourite(species.id)
        } label: {
            HStack(spacing: 12) {
                SpeciesIcon(species: species, size: 32)
                Text(species.commonName)
                    .foregroundStyle(.primary)
                Spacer(minLength: 8)
                Image(systemName: "star")
                    .imageScale(.large)
            }
            .frame(minHeight: settings.buttonSize.minTapSize)
            .contentShape(Rectangle())
        }
        .accessibilityLabel("Add \(species.commonName) to favourites")
    }

    // MARK: Data

    private struct FavouriteGroup: Identifiable {
        let id: String
        let title: String
        let species: [Species]
    }

    /// Ids that no longer match a catalog species are dropped here, and so on the next reorder.
    private var favourites: [Species] {
        settings.favouriteSpeciesIDs.compactMap { SpeciesCatalog.species(id: $0) }
    }

    /// Groups from the catalog's per-region cache, minus what is already pinned. Empty regions
    /// means every species.
    private func otherGroups(regions: Set<FishingRegion>) -> [FavouriteGroup] {
        let pinned = Set(settings.favouriteSpeciesIDs)
        return SpeciesCatalog.grouped(in: regions).compactMap { entry -> FavouriteGroup? in
            let members = entry.species.filter { !pinned.contains($0.id) }
            guard !members.isEmpty else { return nil }
            return FavouriteGroup(id: entry.group.rawValue, title: entry.group.label, species: members)
        }
    }

    private func move(from source: IndexSet, to destination: Int) {
        var ids = favourites.map(\.id)
        ids.move(fromOffsets: source, toOffset: destination)
        settings.favouriteSpeciesIDs = ids
    }

    private func remove(at offsets: IndexSet) {
        var ids = favourites.map(\.id)
        ids.remove(atOffsets: offsets)
        settings.favouriteSpeciesIDs = ids
    }
}

#Preview {
    NavigationStack {
        SettingsFavouritesView()
    }
    .environment(AppSettings.shared)
}
