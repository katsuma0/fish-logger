import Combine
import SwiftData
import SwiftUI
import UIKit

/// Field guide page for one species, with your own catches of it underneath. Pushed, never a root.
/// Reads as reference first: logging is a plain bordered button, and it asks before starting a trip.
struct SpeciesDetailView: View {
    let species: Species

    @Environment(AppSettings.self) private var settings
    @Environment(\.modelContext) private var modelContext
    /// The latest catches of this species, newest first. Filtered and capped in the store, so a
    /// species that fills most of a long log still loads only the rows the page shows.
    @Query private var catches: [FishCatch]
    /// Totals over every catch of this species, from a small fetch after each save rather than in `body`.
    @State private var totals: SpeciesCatchTotals?
    /// Goes up on a save while the page is on screen, so the totals are counted again.
    @State private var saves = 0
    /// Set by every save and cleared when the totals are counted. While another tab or a pushed page
    /// covers this one, a save is only noted and counted when the page comes back, so logging on
    /// Today never waits on this page, and coming back with nothing new costs no fetch.
    @State private var totalsAreStale = true
    @State private var isOnScreen = false
    /// The running trip, if any. Decides whether logging needs a trip started first.
    @Query(filter: #Predicate<Trip> { $0.endDate == nil }) private var openTrips: [Trip]
    @State private var editingCatch: FishCatch?
    /// Shows the logged toast with Undo. The toast sets it back to nil when it hides.
    @State private var loggedCatch: FishCatch?
    @State private var confirmingStartTrip = false
    /// The last catch logged here and the trip that logging started, if it started one. Undo then
    /// takes the empty trip away too, so the page leaves things as they were. An id, not the model,
    /// because reading a deleted model can crash.
    @State private var lastLoggedID: UUID?
    @State private var startedTrip: Trip?

    init(species: Species) {
        self.species = species
        // A local constant, because the predicate macro cannot capture a property of self.
        let speciesID = species.id
        var descriptor = FetchDescriptor<FishCatch>(
            predicate: #Predicate<FishCatch> { $0.speciesID == speciesID },
            sortBy: [SortDescriptor(\FishCatch.timestamp, order: .reverse)]
        )
        descriptor.fetchLimit = SpeciesDetailCatchesSection.recentLimit
        _catches = Query(descriptor)
    }

    var body: some View {
        let isFavourite = settings.isFavourite(species.id)
        let favouriteLabel = isFavourite ? "Remove from favourites" : "Add to favourites"

        List {
            headerSection
            // A forgotten trip counts as none, since logging closes it and starts a new one.
            logSection(hasTrip: openTrips.first.map { !CatchLogger.isForgotten($0) } ?? false)
            identificationSection
            lookalikesSection
            sizeGuideSection
            whereSection
            SpeciesDetailCatchesSection(catches: catches, totals: totals) { fishCatch in
                editingCatch = fishCatch
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(species.commonName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
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
        .loggedToast($loggedCatch)
        .onChange(of: loggedCatch == nil) { _, hidden in
            if hidden { toastHidden() }
        }
        // Logging here, Undo, the catch editor, and logging on another tab all save.
        .onReceive(NotificationCenter.default.publisher(for: ModelContext.didSave).receive(on: DispatchQueue.main)) { _ in
            totalsAreStale = true
            if isOnScreen { saves += 1 }
        }
        .onAppear {
            isOnScreen = true
            if totalsAreStale { saves += 1 }
        }
        .onDisappear { isOnScreen = false }
        .task(id: saves) {
            if totalsAreStale { loadTotals() }
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

    /// Says what will happen: with no trip running, the label and a question make the new trip plain.
    private func logSection(hasTrip: Bool) -> some View {
        Section {
            Button {
                logTapped()
            } label: {
                Label(hasTrip ? "Log one now" : "Start a trip and log one", systemImage: "plus.circle")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, minHeight: settings.buttonSize.minTapSize)
            }
            .buttonStyle(.bordered)
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .accessibilityHint(hasTrip ? "Adds one to the current trip." : "Asks before starting a trip.")
            .confirmationDialog(
                startTripQuestion,
                isPresented: $confirmingStartTrip,
                titleVisibility: .visible
            ) {
                Button("Start trip and log") { log() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("No trip is running, so this starts one here and now.")
            }
        }
    }

    /// "Start a trip and log a Walleye?", or "an" before a vowel, as in "an Arctic char".
    private var startTripQuestion: String {
        let name = species.commonName
        let article = name.first.map { "AEIOUaeiou".contains($0) } == true ? "an" : "a"
        return "Start a trip and log \(article) \(name)?"
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
                    SpeciesDetailTextRow(title: "Range", text: species.range)
                }
            }
        }
    }

    // MARK: Actions

    private func loadTotals() {
        totalsAreStale = false
        let counted = SpeciesCatchTotals.load(speciesID: species.id, in: modelContext)
        if counted != totals { totals = counted }
    }

    /// Logs straight away during a trip. Reading the guide at home, a stray tap must not start a
    /// trip with a fish in it, so with no trip running it asks first.
    private func logTapped() {
        if CatchLogger.currentTrip(in: modelContext) != nil {
            log()
        } else {
            confirmingStartTrip = true
        }
    }

    private func log() {
        let tripBefore = CatchLogger.currentTrip(in: modelContext)
        let fishCatch = CatchLogger.logCatch(speciesID: species.id, in: modelContext)
        Haptics.logged()
        if let trip = fishCatch.trip, trip.id != tripBefore?.id {
            startedTrip = trip
            // A fresh trip still needs GPS, weather, and moon; fill them in without blocking the tap.
            Task {
                await TripConditionsUpdater.refresh(trip, in: modelContext)
            }
        } else {
            startedTrip = nil
        }
        lastLoggedID = fishCatch.id
        // The toast reads itself out for VoiceOver and offers Undo.
        loggedCatch = fishCatch
    }

    /// Runs when the toast goes away, whether it timed out or Undo was tapped. After an Undo, a trip
    /// that this page started and that now holds nothing is removed too.
    private func toastHidden() {
        guard let loggedID = lastLoggedID else { return }
        let started = startedTrip
        lastLoggedID = nil
        startedTrip = nil
        guard let trip = started, !trip.isDeleted, trip.modelContext != nil else { return }
        let stillLogged = FetchDescriptor<FishCatch>(predicate: #Predicate<FishCatch> { $0.id == loggedID })
        // Timed out or closed: the catch is still there, so the trip stays.
        guard ((try? modelContext.fetchCount(stillLogged)) ?? 1) == 0 else { return }
        let hasCatches = trip.catches.contains { !$0.isDeleted && $0.modelContext != nil }
        if !hasCatches {
            CatchLogger.delete(trip, in: modelContext)
        }
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
