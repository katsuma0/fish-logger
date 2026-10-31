import SwiftData
import SwiftUI
import UIKit

/// Field guide page for one species, with your own catches of it underneath. Pushed, never a root.
struct SpeciesDetailView: View {
    let species: Species

    @Environment(AppSettings.self) private var settings
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FishCatch.timestamp, order: .reverse) private var allCatches: [FishCatch]
    @State private var editingCatch: FishCatch?
    @State private var confirmation: String?
    @State private var confirmationID = 0

    init(species: Species) {
        self.species = species
    }

    var body: some View {
        // Filtered in Swift because a predicate cannot reliably capture a property of a plain struct.
        let catches = allCatches.filter { $0.speciesID == species.id }
        let isFavourite = settings.isFavourite(species.id)
        let favouriteLabel = isFavourite ? "Remove from favourites" : "Add to favourites"

        List {
            headerSection
            logSection
            identificationSection
            lookalikesSection
            sizeGuideSection
            whereSection
            SpeciesDetailCatchesSection(catches: catches) { fishCatch in
                editingCatch = fishCatch
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(species.commonName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Haptics.tap()
                    settings.toggleFavourite(species.id)
                } label: {
                    Image(systemName: isFavourite ? "star.fill" : "star")
                }
                .accessibilityLabel(favouriteLabel)
            }
        }
        .sheet(item: $editingCatch) { fishCatch in
            NavigationStack {
                CatchEditorView(fishCatch: fishCatch)
            }
        }
        .task(id: confirmationID) {
            guard confirmation != nil else { return }
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            guard !Task.isCancelled else { return }
            withAnimation { confirmation = nil }
        }
    }

    // MARK: Sections

    @ViewBuilder
    private var headerSection: some View {
        Section {
            HStack(alignment: .center, spacing: 16) {
                SpeciesIcon(species: species, size: 72)
                VStack(alignment: .leading, spacing: 4) {
                    Text(species.commonName)
                        .font(.title2)
                        .bold()
                    if !species.scientificName.isEmpty {
                        Text(species.scientificName)
                            .font(.subheadline)
                            .italic()
                            .foregroundStyle(.secondary)
                    }
                    Text(species.group.label)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color(uiColor: .tertiarySystemFill)))
                }
            }
            .padding(.vertical, 4)
            .accessibilityElement(children: .combine)

            if !species.otherNames.isEmpty {
                Text("Also called \(species.otherNames.joined(separator: ", ")).")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if !species.summary.isEmpty {
                Text(species.summary)
            }
        }
    }

    @ViewBuilder
    private var logSection: some View {
        Section {
            Button {
                logOne()
            } label: {
                Label("Log one now", systemImage: "plus.circle.fill")
            }
            .buttonStyle(PrimaryActionButtonStyle(tint: species.color))
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .accessibilityHint("Adds one to the current trip. Starts a trip if none is running.")
        } footer: {
            if let confirmation {
                Text(confirmation)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .transition(.opacity)
            }
        }
    }

    @ViewBuilder
    private var identificationSection: some View {
        if !species.idTips.isEmpty {
            Section("How to tell it apart") {
                ForEach(species.idTips, id: \.self) { tip in
                    Label(tip, systemImage: "checkmark.circle")
                }
            }
        }
    }

    @ViewBuilder
    private var lookalikesSection: some View {
        let lookalikes = species.lookalikes.compactMap(SpeciesCatalog.species(id:))
        if !lookalikes.isEmpty {
            Section("Looks like") {
                ForEach(lookalikes) { other in
                    NavigationLink {
                        SpeciesDetailView(species: other)
                    } label: {
                        HStack(spacing: 12) {
                            SpeciesIcon(species: other, size: 32)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(other.commonName)
                                    .foregroundStyle(.primary)
                                if !other.scientificName.isEmpty {
                                    Text(other.scientificName)
                                        .font(.caption)
                                        .italic()
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var sizeGuideSection: some View {
        let hasWeights = species.estimatedWeightKg(lengthCm: species.representativeLengthCm(for: .medium)) != nil
        Section {
            ForEach(SizeClass.allCases) { sizeClass in
                SpeciesDetailSizeRow(species: species, sizeClass: sizeClass)
            }
        } header: {
            Text("Size guide")
        } footer: {
            if hasWeights {
                Text("Weights are estimates from a standard length-weight curve.")
            }
        }
    }

    @ViewBuilder
    private var whereSection: some View {
        if !species.habitat.isEmpty || !species.range.isEmpty {
            Section("Where to find it") {
                if !species.habitat.isEmpty {
                    SpeciesDetailTextRow(title: "Habitat", text: species.habitat)
                }
                if !species.range.isEmpty {
                    SpeciesDetailTextRow(title: "Range in Canada", text: species.range)
                }
            }
        }
    }

    // MARK: Actions

    private func logOne() {
        let hadTrip = CatchLogger.activeTrip(in: modelContext) != nil
        let fishCatch = CatchLogger.logCatch(speciesID: species.id, in: modelContext)
        Haptics.logged()
        if !hadTrip, let trip = fishCatch.trip {
            // A fresh trip still needs GPS, weather, and moon; fill them in without blocking the tap.
            Task {
                await TripConditionsUpdater.refresh(trip, in: modelContext)
            }
        }
        let total = fishCatch.trip?.totalFish ?? fishCatch.count
        let message = "Logged. \(total) this trip."
        withAnimation {
            confirmation = message
        }
        confirmationID += 1
        // The footer text is easy to miss with VoiceOver, so read it out too.
        UIAccessibility.post(notification: .announcement, argument: message)
    }
}

/// One size class with its length range and, when the species has a weight curve, a typical weight.
private struct SpeciesDetailSizeRow: View {
    let species: Species
    let sizeClass: SizeClass

    @Environment(AppSettings.self) private var settings

    init(species: Species, sizeClass: SizeClass) {
        self.species = species
        self.sizeClass = sizeClass
    }

    var body: some View {
        let weight = species.estimatedWeightKg(lengthCm: species.representativeLengthCm(for: sizeClass))
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Label(sizeClass.label, systemImage: sizeClass.symbolName)
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 2) {
                Text(rangeText)
                    .foregroundStyle(.secondary)
                if let weight {
                    Text("about \(settings.weight(weight))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .multilineTextAlignment(.trailing)
        }
        .accessibilityElement(children: .combine)
    }

    private var rangeText: String {
        let label = settings.lengthRangeLabel(species, sizeClass)
        guard let first = label.first else { return label }
        return first.uppercased() + String(label.dropFirst())
    }
}

/// Short heading over a paragraph, read as one item.
private struct SpeciesDetailTextRow: View {
    let title: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .bold()
                .foregroundStyle(.secondary)
            Text(text)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    let container = AppModelContainer.inMemory()
    CatchLogger.logCatch(speciesID: "walleye", count: 2, sizeClass: .large, lengthCm: 58, in: container.mainContext)
    return NavigationStack {
        SpeciesDetailView(species: SpeciesCatalog.species(id: "walleye") ?? SpeciesCatalog.unknown)
    }
    .modelContainer(container)
    .environment(AppSettings.shared)
}
