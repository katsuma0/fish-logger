import SwiftUI

/// Searchable species list. Favourites first, then the fish of your regions by group. Search always
/// covers every species, with out-of-region matches listed after, so an odd catch is never unloggable.
/// Present it inside a NavigationStack.
struct SpeciesPickerView: View {
    var title: String = "Pick a species"
    /// Adds an "Unknown fish" row at the top.
    var allowsUnknown: Bool = true
    /// Off when pushed onto a stack, where Back already does the job.
    var showsCancel: Bool = true
    let onPick: (Species) -> Void

    @Environment(AppSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var showsAllRegions = false

    var body: some View {
        // Read once per render and passed down, so rows never go back to settings.
        let homeRegions = settings.homeRegions
        let favouriteIDs = settings.favouriteSpeciesIDs
        List {
            if query.isEmpty {
                browseContent(homeRegions: homeRegions, favouriteIDs: favouriteIDs)
            } else {
                searchContent(homeRegions: homeRegions, favouriteIDs: Set(favouriteIDs))
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Walleye, pike, bass")
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                if showsCancel {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private func browseContent(homeRegions: Set<FishingRegion>, favouriteIDs: [String]) -> some View {
        let favouriteSet = Set(favouriteIDs)
        if allowsUnknown {
            Section {
                row(SpeciesCatalog.unknown, isFavourite: false)
            }
        }
        let favourites = favouriteIDs.compactMap(SpeciesCatalog.species(id:))
        if !favourites.isEmpty {
            Section("Favourites") {
                ForEach(favourites) { row($0, isFavourite: true) }
            }
        }
        // Cached per region set in the catalog, so this is a lookup, not a filter and sort.
        ForEach(SpeciesCatalog.grouped(in: showsAllRegions ? [] : homeRegions), id: \.group) { entry in
            Section(entry.group.label) {
                ForEach(entry.species) { row($0, isFavourite: favouriteSet.contains($0.id)) }
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

    @ViewBuilder
    private func searchContent(homeRegions: Set<FishingRegion>, favouriteIDs: Set<String>) -> some View {
        let results = SpeciesCatalog.search(query)
        let local = results.filter { $0.lives(in: homeRegions) }
        let elsewhere = results.filter { !$0.lives(in: homeRegions) }
        if results.isEmpty {
            ContentUnavailableView.search(text: query)
        } else {
            if !local.isEmpty {
                Section {
                    ForEach(local) { row($0, isFavourite: favouriteIDs.contains($0.id)) }
                }
            }
            if !elsewhere.isEmpty {
                Section("Other regions") {
                    ForEach(elsewhere) { row($0, isFavourite: favouriteIDs.contains($0.id)) }
                }
            }
        }
    }

    /// No haptic here: the screen that asked for the species confirms the pick.
    private func row(_ species: Species, isFavourite: Bool) -> some View {
        Button {
            onPick(species)
            dismiss()
        } label: {
            HStack(spacing: 12) {
                SpeciesIcon(species: species, size: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text(species.commonName)
                        .font(.body)
                        .foregroundStyle(.primary)
                    if !species.otherNames.isEmpty {
                        Text(species.otherNames.prefix(2).joined(separator: ", "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if isFavourite {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                        .accessibilityLabel("Favourite")
                }
            }
            .frame(minHeight: settings.buttonSize.minTapSize)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
