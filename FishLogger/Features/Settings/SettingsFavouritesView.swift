import SwiftUI

/// Pinned species for the quick log grid. Favourites sit on top in grid order; everything else
/// is below, grouped like the species guide, with a star to pin it.
struct SettingsFavouritesView: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
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

            ForEach(otherGroups) { group in
                Section(group.title) {
                    ForEach(group.species) { species in
                        addRow(species)
                    }
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

    private func addRow(_ species: Species) -> some View {
        Button {
            settings.toggleFavourite(species.id)
            Haptics.tap()
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

    private var otherGroups: [FavouriteGroup] {
        let pinned = Set(settings.favouriteSpeciesIDs)
        return SpeciesGroup.allCases.compactMap { group -> FavouriteGroup? in
            let members = SpeciesCatalog.all
                .filter { $0.group == group && !pinned.contains($0.id) }
                .sorted { $0.commonName < $1.commonName }
            guard !members.isEmpty else { return nil }
            return FavouriteGroup(id: group.rawValue, title: group.label, species: members)
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
        Haptics.tap()
    }
}

#Preview {
    NavigationStack {
        SettingsFavouritesView()
    }
    .environment(AppSettings.shared)
}
