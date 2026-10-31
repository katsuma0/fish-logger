import SwiftData
import SwiftUI

/// One trip, start to finish: when and where, conditions, every catch, and the photos.
struct TripDetailView: View {
    let trip: Trip

    @Environment(AppSettings.self) private var settings
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @ScaledMetric(relativeTo: .body) private var mapHeight: CGFloat = 180

    @State private var activeSheet: TripDetailSheet? = nil
    @State private var photoSelection: TripDetailPhotoSelection? = nil
    @State private var isFetchingWeather = false
    @State private var weatherMessage: String? = nil
    @State private var confirmingDelete = false
    /// Worked out when Delete is tapped, so a render never counts every photo on the trip.
    @State private var deleteMessage = ""
    @State private var confirmingEnd = false
    /// Worked out when End trip is tapped, so the dialog and the end time agree. Nil ends the trip now.
    @State private var endDateForStaleTrip: Date? = nil
    @State private var endMessage: String? = nil
    @State private var pendingCatchDelete: TripDetailCatchDeleteRequest? = nil
    /// A catch just added from the species list. Its editor opens once the list has closed, so the time
    /// and size can be set straight away.
    @State private var pendingNewCatch: FishCatch? = nil
    @State private var showingMap = false
    /// Set before deleting so the body stops reading the trip on the way out.
    @State private var didDelete = false
    /// Today's Keep going answer, so End trip here treats a forgotten trip the way Today's card does.
    @AppStorage("todayKeptGoingTripID") private var keptGoingTripID = ""
    @AppStorage("todayKeptGoingAt") private var keptGoingAt: Double = 0

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
                description: Text("It is no longer in the Trips tab.")
            )
        } else {
            detail
        }
    }

    private var detail: some View {
        // Sorted once per render and shared by every section that needs the catches.
        let catches = trip.sortedCatches
        let catchPins = HistoryMapPins.catchPins(for: catches, in: trip)
        let spotPins = HistoryMapPins.spotPins(for: [trip])
        let title = trip.displayName
        return List {
            Section {
                HistoryTripHeader(trip: trip)
            }
            conditionsSection
            mapSection(catchPins: catchPins, spotPins: spotPins)
            speciesSection
            catchesSection(catches)
            photosSection(catches)
            notesSection
            deleteSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if trip.isActive {
                    Button("End trip") { askToEnd() }
                }
                Button("Edit") { activeSheet = .editTrip }
            }
        }
        .navigationDestination(isPresented: $showingMap) {
            HistoryTripMapPage(title: title, catchPins: catchPins, spotPins: spotPins)
        }
        .sheet(item: $activeSheet, onDismiss: openPendingNewCatch) { sheet in
            sheetContent(for: sheet)
        }
        .fullScreenCover(item: $photoSelection) { selection in
            PhotoViewer(photos: selection.photos, startIndex: selection.startIndex)
        }
        .confirmationDialog("End this trip?", isPresented: $confirmingEnd, titleVisibility: .visible) {
            Button("End trip") { endTrip() }
            Button("Cancel", role: .cancel) {}
        } message: {
            if let endMessage {
                Text(endMessage)
            }
        }
        .confirmationDialog(
            "Delete this catch?",
            isPresented: isConfirmingCatchDelete,
            titleVisibility: .visible,
            presenting: pendingCatchDelete
        ) { request in
            Button("Delete catch", role: .destructive) {
                deleteCatch(request.fishCatch)
            }
            Button("Cancel", role: .cancel) {}
        } message: { request in
            Text(request.message)
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

    /// A still picture of the trip. Tapping it opens a full map that pans and zooms.
    @ViewBuilder
    private func mapSection(catchPins: [HistoryMapPin], spotPins: [HistoryMapPin]) -> some View {
        if !catchPins.isEmpty || !spotPins.isEmpty {
            Section {
                Button {
                    showingMap = true
                } label: {
                    HistoryTripMapSnippet(catchPins: catchPins, spotPins: spotPins)
                        // The button takes the tap; the map underneath only draws.
                        .allowsHitTesting(false)
                        // Grows with text size, capped so the map never fills the screen.
                        .frame(height: min(mapHeight, 280))
                        .overlay(alignment: .topTrailing) {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.primary)
                                .padding(8)
                                .background(.regularMaterial, in: Circle())
                                .padding(8)
                                .accessibilityHidden(true)
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityHint("Opens a bigger map you can move around")
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

    private func catchesSection(_ catches: [FishCatch]) -> some View {
        let fish = catches.reduce(0) { $0 + $1.count }
        let title: String = catches.isEmpty ? "Catches" : "Catches, \(HistoryText.fish(fish))"
        return Section {
            ForEach(catches) { fishCatch in
                Button {
                    activeSheet = .editCatch(fishCatch)
                } label: {
                    CatchRow(fishCatch: fishCatch)
                }
                .foregroundStyle(.primary)
                .accessibilityHint("Opens the catch details")
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    // Not a destructive role: that removes the row before the angler confirms.
                    Button {
                        askToDelete(fishCatch)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    .tint(.red)
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
    private func photosSection(_ catches: [FishCatch]) -> some View {
        let photos = catches.flatMap { $0.sortedPhotos }
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
                deleteMessage = HistoryText.deleteMessage(for: trip)
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
                Text(deleteMessage)
            }
        }
    }

    private var isConfirmingCatchDelete: Binding<Bool> {
        Binding(
            get: { pendingCatchDelete != nil },
            set: { isPresented in
                if !isPresented { pendingCatchDelete = nil }
            }
        )
    }

    // MARK: Actions

    private func fillWeather() {
        guard !isFetchingWeather else { return }
        isFetchingWeather = true
        weatherMessage = nil
        let context = modelContext
        Task {
            await fillEmptyWeather(in: context)
            isFetchingWeather = false
            guard !didDelete, !trip.historyIsGone else { return }
            if hasWeather {
                Haptics.tap()
            } else {
                weatherMessage = "Could not get the weather. Check the connection and try again."
            }
        }
    }

    /// Fills only the weather fields that are empty. This button shows while cloud cover, rain, wind
    /// direction or the trend may still hold values typed under Edit, and those stay. Get weather in the
    /// editor is the one that replaces them, and its footer says so.
    private func fillEmptyWeather(in context: ModelContext) async {
        if trip.coordinate == nil {
            // An open trip with no spot yet: this finds one. Any weather it fetches only fills empty fields.
            await TripConditionsUpdater.refresh(trip, in: context)
            guard !didDelete, !trip.historyIsGone, !hasWeather else { return }
        }
        guard let latitude = trip.latitude, let longitude = trip.longitude,
              let snapshot = try? await WeatherService.fetch(latitude: latitude, longitude: longitude, at: trip.startDate)
        else { return }
        guard !didDelete, !trip.historyIsGone else { return }
        WeatherService.apply(snapshot, to: trip, overwrite: false)
        // Names the spot, fills sun and moon, and saves. The weather is already in, so it is not fetched again.
        await TripConditionsUpdater.refresh(trip, in: context)
    }

    private func addCatch(_ species: Species) {
        guard !didDelete, !trip.historyIsGone else { return }
        let fishCatch = CatchLogger.logCatch(speciesID: species.id, to: trip, in: modelContext)
        Haptics.logged()
        pendingNewCatch = fishCatch
    }

    /// Runs whenever a sheet closes. After an add, the species list has just gone, so the new catch's
    /// editor comes up. A catch added to a finished trip is stamped at the trip's end until its time is set.
    private func openPendingNewCatch() {
        guard let fishCatch = pendingNewCatch else { return }
        pendingNewCatch = nil
        guard !didDelete, !fishCatch.isDeleted, fishCatch.modelContext != nil else { return }
        activeSheet = .editCatch(fishCatch)
    }

    /// The message is worked out now so the dialog never reads a catch that was just deleted.
    private func askToDelete(_ fishCatch: FishCatch) {
        pendingCatchDelete = TripDetailCatchDeleteRequest(
            fishCatch: fishCatch,
            message: HistoryText.catchDeleteMessage(for: fishCatch)
        )
    }

    private func deleteCatch(_ fishCatch: FishCatch) {
        // Clear the request first so nothing reads the catch after it is gone.
        pendingCatchDelete = nil
        guard !fishCatch.isDeleted, fishCatch.modelContext != nil else { return }
        CatchLogger.delete(fishCatch, in: modelContext)
        Haptics.warning()
    }

    /// A trip that looks forgotten, by the same rule as Today's card, ends at its last fish (or its start
    /// when it has none), whichever End button is used. Ending it now would count days nobody fished.
    private func askToEnd() {
        let keptGoing = keptGoingTripID == trip.id.uuidString ? Date(timeIntervalSince1970: keptGoingAt) : nil
        if TodayStaleTripCard.isStale(trip, keptGoingAt: keptGoing) {
            let date = TodayStaleTripCard.endDate(for: trip)
            endDateForStaleTrip = date
            endMessage = TripDetailEndText.message(endingAt: date, atLastFish: !trip.catches.isEmpty)
        } else {
            endDateForStaleTrip = nil
            endMessage = nil
        }
        confirmingEnd = true
    }

    private func endTrip() {
        guard !didDelete, !trip.historyIsGone, trip.isActive else { return }
        CatchLogger.endTrip(trip, in: modelContext, at: endDateForStaleTrip ?? .now)
        endDateForStaleTrip = nil
        Haptics.tap()
    }

    private func deleteTrip() {
        didDelete = true
        activeSheet = nil
        photoSelection = nil
        pendingNewCatch = nil
        CatchLogger.delete(trip, in: modelContext)
        Haptics.warning()
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

/// The End trip dialog's note for a trip that ends earlier than now.
private enum TripDetailEndText {
    /// "Ends at your last fish, 11:02 AM.", with the day added when it was not today.
    static func message(endingAt date: Date, atLastFish: Bool, now: Date = .now) -> String {
        let time = date.formatted(date: .omitted, time: .shortened)
        let when = Calendar.current.isDate(date, inSameDayAs: now) ? time : "\(HistoryText.dayTitle(date, now: now)) at \(time)"
        let lead = atLastFish ? "Ends at your last fish, \(when)." : "No fish logged, so it ends at its start time, \(when)."
        return "\(lead) You can change the time under Edit."
    }
}

/// A swipe Delete waiting for the angler to confirm.
private struct TripDetailCatchDeleteRequest {
    let fishCatch: FishCatch
    let message: String
}

private struct TripDetailPhotoSelection: Identifiable {
    let id = UUID()
    let photos: [CatchPhoto]
    let startIndex: Int
}
