import SwiftUI

/// Searchable species list. Favourites first, then the fish of your regions by group. Search always
/// covers every species, with out-of-region matches listed after, so an odd catch is never unloggable.
/// Present it inside a NavigationStack.
struct SpeciesPickerView: View {
    var title: String = "Pick a species"
    /// Adds an "Unknown fish" row at the top.
    var allowsUnknown: Bool = true
    let onPick: (Species) -> Void

    @Environment(AppSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var showsAllRegions = false

    private var regions: Set<FishingRegion> { showsAllRegions ? [] : settings.homeRegions }

    var body: some View {
        List {
            if query.isEmpty {
                browseContent
            } else {
                searchContent
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Walleye, pike, bass")
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
    }

    @ViewBuilder
    private var browseContent: some View {
        if allowsUnknown {
            Section {
                row(SpeciesCatalog.unknown)
            }
        }
        let favourites = settings.favouriteSpeciesIDs.compactMap(SpeciesCatalog.species(id:))
        if !favourites.isEmpty {
            Section("Favourites") {
                ForEach(favourites) { row($0) }
            }
        }
        ForEach(SpeciesCatalog.grouped(in: regions), id: \.group) { entry in
            Section(entry.group.label) {
                ForEach(entry.species) { row($0) }
            }
        }
        if !settings.homeRegions.isEmpty {
            Section {
                Button {
                    withAnimation { showsAllRegions.toggle() }
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
    private var searchContent: some View {
        let results = SpeciesCatalog.search(query)
        let local = results.filter { $0.lives(in: settings.homeRegions) }
        let elsewhere = results.filter { !$0.lives(in: settings.homeRegions) }
        if results.isEmpty {
            ContentUnavailableView.search(text: query)
        } else {
            if !local.isEmpty {
                Section {
                    ForEach(local) { row($0) }
                }
            }
            if !elsewhere.isEmpty {
                Section("Other regions") {
                    ForEach(elsewhere) { row($0) }
                }
            }
        }
    }

    private func row(_ species: Species) -> some View {
        Button {
            Haptics.tap()
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
                if settings.isFavourite(species.id) {
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
