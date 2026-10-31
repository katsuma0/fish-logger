import SwiftData
import SwiftUI

/// One trip, start to finish: when and where, conditions, every catch, and the photos.
struct TripDetailView: View {
    let trip: Trip

    @Environment(AppSettings.self) private var settings
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var activeSheet: TripDetailSheet? = nil
    @State private var photoSelection: TripDetailPhotoSelection? = nil
    @State private var isFetchingWeather = false
    @State private var weatherMessage: String? = nil
    @State private var confirmingDelete = false
    @State private var confirmingEnd = false
    /// Set before deleting so the body stops reading the trip on the way out.
    @State private var didDelete = false

    init(trip: Trip) {
        self.trip = trip
    }

    var body: some View {
        if didDelete {
            Color.clear
        } else if trip.historyIsGone {
            ContentUnavailableView(
                "Trip deleted",
                systemImage: "trash",
                description: Text("This trip is no longer in the log.")
            )
        } else {
            detail
        }
    }

    private var detail: some View {
        List {
            Section {
                HistoryTripHeader(trip: trip)
            }
            conditionsSection
            mapSection
            speciesSection
            catchesSection
            photosSection
            notesSection
            deleteSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle(trip.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if trip.isActive {
                    Button("End trip") { confirmingEnd = true }
                }
                Button("Edit") { activeSheet = .editTrip }
            }
        }
        .sheet(item: $activeSheet) { sheet in
            sheetContent(for: sheet)
        }
        .fullScreenCover(item: $photoSelection) { selection in
            PhotoViewer(photos: selection.photos, startIndex: selection.startIndex)
        }
        .confirmationDialog("End this trip?", isPresented: $confirmingEnd, titleVisibility: .visible) {
            Button("End trip") { endTrip() }
            Button("Cancel", role: .cancel) {}
        }
    }

    @ViewBuilder
    private func sheetContent(for sheet: TripDetailSheet) -> some View {
        switch sheet.kind {
        case .editTrip:
            NavigationStack {
                TripEditorView(trip: trip)
            }
        case .editCatch(let fishCatch):
            NavigationStack {
                CatchEditorView(fishCatch: fishCatch)
            }
        case .addCatch:
            NavigationStack {
                SpeciesPickerView(title: "Add a catch", allowsUnknown: true, onPick: { species in
                    addCatch(species)
                })
            }
        }
    }

    // MARK: Sections

    private var hasWeather: Bool {
        trip.weather != nil || trip.airTempC != nil || trip.pressureHPa != nil || trip.windSpeedKmh != nil
    }

    private var hasAnyConditions: Bool {
        hasWeather || trip.waterTempC != nil || trip.moonPhase != nil || trip.sunrise != nil || trip.sunset != nil
    }

    private var weatherIsTooOld: Bool {
        let limit = Date.now.addingTimeInterval(-Double(WeatherService.maxPastDays) * 86_400)
        return trip.startDate < limit
    }

    private var conditionsSection: some View {
        Section("Conditions") {
            if hasAnyConditions {
                ConditionsSummaryView(trip: trip)
                    .padding(.vertical, 4)
            }
            if !hasWeather {
                weatherFiller
            }
        }
    }

    private var weatherFiller: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(hasAnyConditions ? "No weather recorded." : "No conditions recorded.")
                .foregroundStyle(.secondary)
            if weatherIsTooOld {
                Text("Weather history only goes back \(WeatherService.maxPastDays) days. You can enter it by hand under Edit.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else if trip.coordinate == nil && !trip.isActive {
                Text("No location was saved for this trip, so weather cannot be looked up. You can enter it by hand under Edit.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                Button {
                    fillWeather()
                } label: {
                    HStack(spacing: 8) {
                        if isFetchingWeather {
                            ProgressView()
                        } else {
                            Image(systemName: "cloud.sun")
                        }
                        Text(isFetchingWeather ? "Getting weather" : "Fill in weather")
                    }
                    .frame(minHeight: settings.buttonSize.minTapSize)
                }
                .buttonStyle(.bordered)
                .disabled(isFetchingWeather)
            }
            if let weatherMessage {
                Text(weatherMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var mapSection: some View {
        let catchPins = HistoryMapPins.catchPins(for: [trip], speciesID: nil)
        let spotPins = HistoryMapPins.spotPins(for: [trip])
        if !catchPins.isEmpty || !spotPins.isEmpty {
            Section {
                HistoryTripMapSnippet(catchPins: catchPins, spotPins: spotPins)
                    .frame(height: 180)
                    .listRowInsets(EdgeInsets())
            }
        }
    }

    @ViewBuilder
    private var speciesSection: some View {
        let tally = trip.historySpeciesCounts
        if !tally.isEmpty {
            Section("Species") {
                FlowLayout(spacing: 8, lineSpacing: 8) {
                    ForEach(tally) { entry in
                        HistorySpeciesChip(entry: entry)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private var catchesSection: some View {
        let catches = trip.sortedCatches
        let title: String = catches.isEmpty ? "Catches" : "Catches, \(HistoryText.fish(trip.totalFish))"
        return Section {
            ForEach(catches) { fishCatch in
                Button {
                    activeSheet = .editCatch(fishCatch)
                } label: {
                    CatchRow(fishCatch: fishCatch)
                }
                .foregroundStyle(.primary)
                .accessibilityHint("Opens the catch details")
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        deleteCatch(fishCatch)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            Button {
                activeSheet = .addCatch
            } label: {
                Label("Add a catch", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity, minHeight: settings.buttonSize.minTapSize, alignment: .leading)
                    .contentShape(Rectangle())
            }
        } header: {
            Text(title)
        } footer: {
            if catches.isEmpty {
                Text("No fish logged on this trip.")
            }
        }
    }

    @ViewBuilder
    private var photosSection: some View {
        let photos = trip.sortedCatches.flatMap { $0.sortedPhotos }
        if !photos.isEmpty {
            Section("Photos") {
                HistoryPhotoStrip(photos: photos, onOpen: { index in
                    photoSelection = TripDetailPhotoSelection(photos: photos, startIndex: index)
                })
            }
        }
    }

    @ViewBuilder
    private var notesSection: some View {
        let notes = trip.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        if !notes.isEmpty {
            Section("Notes") {
                Text(notes)
                    .textSelection(.enabled)
            }
        }
    }

    private var deleteSection: some View {
        Section {
            Button(role: .destructive) {
                confirmingDelete = true
            } label: {
                Text("Delete trip")
                    .frame(maxWidth: .infinity, minHeight: settings.buttonSize.minTapSize)
                    .contentShape(Rectangle())
            }
            // Weather lands on the trip when the fetch returns, so it has to finish first.
            .disabled(isFetchingWeather)
            .confirmationDialog("Delete this trip?", isPresented: $confirmingDelete, titleVisibility: .visible) {
                Button("Delete trip", role: .destructive) { deleteTrip() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(HistoryText.deleteMessage(for: trip))
            }
        }
    }

    // MARK: Actions

    private func fillWeather() {
        guard !isFetchingWeather else { return }
        isFetchingWeather = true
        weatherMessage = nil
        let context = modelContext
        Task {
            await TripConditionsUpdater.refresh(trip, in: context, forceWeather: true)
            isFetchingWeather = false
            guard !didDelete, !trip.historyIsGone else { return }
            if hasWeather {
                Haptics.tap()
            } else {
                weatherMessage = "Could not get the weather. Check the connection and try again."
            }
        }
    }

    private func addCatch(_ species: Species) {
        guard !didDelete else { return }
        CatchLogger.logCatch(speciesID: species.id, to: trip, in: modelContext)
        Haptics.logged()
    }

    private func deleteCatch(_ fishCatch: FishCatch) {
        CatchLogger.delete(fishCatch, in: modelContext)
        Haptics.tap()
    }

    private func endTrip() {
        CatchLogger.endTrip(trip, in: modelContext)
        Haptics.tap()
    }

    private func deleteTrip() {
        didDelete = true
        activeSheet = nil
        photoSelection = nil
        CatchLogger.delete(trip, in: modelContext)
        Haptics.tap()
        dismiss()
    }
}

/// What the one sheet on this screen is showing. The id is worked out up front so SwiftUI never has
/// to read a catch that the editor just deleted.
private struct TripDetailSheet: Identifiable {
    enum Kind {
        case editTrip
        case editCatch(FishCatch)
        case addCatch
    }

    let id: String
    let kind: Kind

    static var editTrip: TripDetailSheet { TripDetailSheet(id: "editTrip", kind: .editTrip) }

    static var addCatch: TripDetailSheet { TripDetailSheet(id: "addCatch", kind: .addCatch) }

    static func editCatch(_ fishCatch: FishCatch) -> TripDetailSheet {
        TripDetailSheet(id: "editCatch-\(fishCatch.id.uuidString)", kind: .editCatch(fishCatch))
    }
}

private struct TripDetailPhotoSelection: Identifiable {
    let id = UUID()
    let photos: [CatchPhoto]
    let startIndex: Int
}
