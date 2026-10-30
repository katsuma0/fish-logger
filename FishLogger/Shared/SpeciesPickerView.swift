import SwiftUI

/// Searchable species list. Favourites first, then every group. Present it inside a NavigationStack.
struct SpeciesPickerView: View {
    var title: String = "Pick a species"
    /// Adds an "Unknown fish" row at the top.
    var allowsUnknown: Bool = true
    let onPick: (Species) -> Void

    @Environment(AppSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    var body: some View {
        List {
            if query.isEmpty {
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
                ForEach(SpeciesCatalog.grouped, id: \.group) { entry in
                    Section(entry.group.label) {
                        ForEach(entry.species) { row($0) }
                    }
                }
            } else {
                let results = SpeciesCatalog.search(query)
                if results.isEmpty {
                    ContentUnavailableView.search(text: query)
                } else {
                    ForEach(results) { row($0) }
                }
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
