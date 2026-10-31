import Combine
import PhotosUI
import SwiftData
import SwiftUI
import UIKit

/// Everything a sheet on the Today screen can show. One `.sheet(item:)` keeps presentations from
/// fighting each other when a tile, the logged confirmation, and the trip list all want to open something.
enum TodaySheet: Identifiable {
    case startTrip
    case editTrip(Trip)
    case editCatch(FishCatch)
    case setSize(FishCatch)
    case pickSpecies
    case identify
    case lastTrip(Trip)

    var id: String {
        switch self {
        case .startTrip:
            return "startTrip"
        case .editTrip(let trip):
            return "editTrip-\(trip.id.uuidString)"
        case .editCatch(let fishCatch):
            return "editCatch-\(fishCatch.id.uuidString)"
        case .setSize(let fishCatch):
            return "setSize-\(fishCatch.id.uuidString)"
        case .pickSpecies:
            return "pickSpecies"
        case .identify:
            return "identify"
        case .lastTrip(let trip):
            return "lastTrip-\(trip.id.uuidString)"
        }
    }
}

/// What the tile order depends on. A change re-checks the grid; a running trip only ever grows it.
private struct TodayGridKey: Equatable {
    let tripID: UUID?
    let catchCount: Int
    let favourites: [String]
    let regions: Set<FishingRegion>
    let groups: Set<SpeciesGroup>
    let mostLogged: [String]?
}

/// The idle card's text and the trip it opens, fetched once rather than worked out on every render.
private struct TodayIdleInfo {
    var summary = " "
    var lastTrip: Trip?
}

/// Whether the catch history behind the idle grid changed since it was last fetched. A class, so a
/// save noting it does not redraw the screen.
private final class TodayHistoryCache {
    var isStale = true
}

/// The on-the-water screen. One tap logs a fish, and nothing moves the tiles while a trip runs.
struct TodayView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @Query(filter: #Predicate<Trip> { $0.endDate == nil }, sort: \Trip.startDate, order: .reverse)
    private var openTrips: [Trip]

    @State private var activeSheet: TodaySheet?
    @State private var showingEndConfirmation = false
    @State private var logged: TodayLoggedInfo?
    @State private var loggedCatch: FishCatch?
    /// The trip the confirmed log started, so Undo can take it away again if it is left empty.
    @State private var loggedStartedTrip: Trip?
    @State private var photoTarget: FishCatch?
    @State private var showingCamera = false
    @State private var showingPhotoPicker = false
    @State private var pickedPhoto: PhotosPickerItem?
    @State private var tileOrder = TodayTileOrder.load()
    /// Nil until the first fetch, so the grid keeps its last order instead of shuffling as it loads.
    @State private var mostLoggedIDs: [String]?
    @State private var historyCache = TodayHistoryCache()
    @State private var idle = TodayIdleInfo()
    @State private var staleTripID: UUID?
    @State private var refreshedTripIDs: Set<UUID> = []
    @State private var isFetchingWeather = false
    /// Keep going on the stale trip card, remembered so the question does not come straight back.
    @AppStorage("todayKeptGoingTripID") private var keptGoingTripID = ""
    @AppStorage("todayKeptGoingAt") private var keptGoingAt: Double = 0

    private var activeTrip: Trip? { openTrips.first }

    var body: some View {
        let trip = activeTrip
        let counts = Self.counts(for: trip)

        NavigationStack {
            ScrollView {
                scrollContent(trip: trip, counts: counts)
            }
            .background(Theme.screenBackground)
            .overlay(alignment: .top) {
                loggedOverlay
            }
            .navigationTitle("Today")
            .toolbar {
                toolbarContent(hasTrip: trip != nil)
            }
            .confirmationDialog("End this trip?", isPresented: $showingEndConfirmation, titleVisibility: .visible) {
                Button("End trip") { endActiveTrip() }
                Button("Keep fishing", role: .cancel) {}
            } message: {
                Text(endTripMessage)
            }
        }
        .onChange(of: gridKey(for: trip), initial: true) {
            refreshTiles()
        }
        .onChange(of: trip?.id, initial: true) {
            activeTripChanged()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { checkStaleTrip() }
        }
        .task {
            await screenAppeared()
        }
        // Every write goes through the main context, so this runs as the save happens, on any tab.
        .onReceive(NotificationCenter.default.publisher(for: ModelContext.didSave)) { _ in
            historyCache.isStale = true
        }
        .sheet(item: $activeSheet, onDismiss: { sheetDismissed() }) { sheet in
            sheetContent(for: sheet)
                .environment(settings)
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraPicker(onCapture: { image in
                attachPhoto(image)
            })
            .ignoresSafeArea()
        }
        .photosPicker(isPresented: $showingPhotoPicker, selection: $pickedPhoto, matching: .images)
        .onChange(of: pickedPhoto) { _, item in
            guard let item else { return }
            pickedPhoto = nil
            attachPickedPhoto(item)
        }
    }

    // MARK: Sections

    private func scrollContent(trip: Trip?, counts: [String: Int]) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            statusSection(trip: trip, counts: counts)

            quickLogSection(trip: trip, counts: counts)

            if let trip {
                TodayConditionsCard(
                    trip: trip,
                    isFetchingWeather: isFetchingWeather,
                    onGetWeather: { fetchWeather(for: trip) }
                )
            }

            if let trip, !trip.catches.isEmpty {
                TodayCatchList(
                    catches: trip.sortedCatches,
                    onOpen: { fishCatch in activeSheet = .editCatch(fishCatch) },
                    onAnother: { fishCatch in logAnother(like: fishCatch) },
                    onDelete: { fishCatch in delete(fishCatch) }
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    /// The trip header, the stale trip question, or the idle card. All three sit in the same slot at
    /// about the same height, so the grid below barely moves when one replaces another.
    @ViewBuilder
    private func statusSection(trip: Trip?, counts: [String: Int]) -> some View {
        if let trip {
            if staleTripID == trip.id {
                TodayStaleTripCard(
                    trip: trip,
                    onEnd: { endStaleTrip(trip) },
                    onKeepGoing: { keepGoing(trip) }
                )
            } else {
                TodayTripHeader(
                    trip: trip,
                    speciesCount: counts.keys.filter { $0 != SpeciesCatalog.unknownID }.count,
                    onEdit: { activeSheet = .editTrip(trip) }
                )
            }
        } else {
            idleSection
        }
    }

    private var idleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            TodayIdleCard(
                summary: idle.summary,
                onOpenLastTrip: openLastTrip
            )
            Button {
                activeSheet = .startTrip
            } label: {
                Label("Start fishing", systemImage: "figure.fishing")
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .accessibilityHint("Pick the spot and start a trip")
        }
    }

    private var openLastTrip: (() -> Void)? {
        guard let last = idle.lastTrip else { return nil }
        return { activeSheet = .lastTrip(last) }
    }

    private func quickLogSection(trip: Trip?, counts: [String: Int]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Log a fish")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                // Same length either way, so the grid does not shift when the first fish starts a trip.
                Text(trip == nil ? "Tap a fish to log it. A trip starts on its own." : "Tap a fish to log it. Press and hold for more.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(trip != nil)
            }
            TodayQuickLogGrid(
                species: tileOrder.speciesIDs.compactMap { SpeciesCatalog.species(id: $0) },
                counts: counts,
                onLog: { species, count in log(species, count: count) },
                onLogWithDetails: { species in log(species, openDetails: true) },
                onOtherFish: { activeSheet = .pickSpecies },
                onPhotoID: { openPhotoID() }
            )
        }
    }

    /// Floats under the navigation bar, over the trip header, so it never covers the tiles.
    private var loggedOverlay: some View {
        ZStack(alignment: .top) {
            if let info = logged {
                TodayLoggedBanner(
                    info: info,
                    isPaused: activeSheet != nil || showingCamera || showingPhotoPicker,
                    onSize: { openSize() },
                    onPhoto: { openPhoto() },
                    onUndo: { undoLastLog() },
                    onClose: { hideLogged() }
                )
                .padding(.horizontal, 12)
                .padding(.top, 4)
                .transition(loggedTransition)
            }
        }
        .animation(reduceMotion ? Animation.easeInOut(duration: 0.2) : Animation.easeOut(duration: 0.25), value: logged?.token)
    }

    @ToolbarContentBuilder
    private func toolbarContent(hasTrip: Bool) -> some ToolbarContent {
        // On the thumb side, like the rest of the left-handed layout.
        ToolbarItem(placement: settings.leftHanded ? ToolbarItemPlacement.topBarLeading : ToolbarItemPlacement.topBarTrailing) {
            Button {
                openPhotoID()
            } label: {
                Label("Photo ID", systemImage: "camera")
            }
            .accessibilityHint("Take or pick a photo and get a species suggestion")
        }
        ToolbarItem(placement: .topBarTrailing) {
            if hasTrip {
                Button("End trip") {
                    showingEndConfirmation = true
                }
            }
        }
    }

    @ViewBuilder
    private func sheetContent(for sheet: TodaySheet) -> some View {
        switch sheet {
        case .startTrip:
            TodayStartTripSheet(lastTrip: idle.lastTrip, onStart: { trip in
                _ = refreshedTripIDs.insert(trip.id)
            })
        case .editTrip(let trip):
            NavigationStack {
                TripEditorView(trip: trip)
            }
        case .editCatch(let fishCatch):
            NavigationStack {
                CatchEditorView(fishCatch: fishCatch)
            }
        case .setSize(let fishCatch):
            TodaySizeSheet(
                fishCatch: fishCatch,
                onChange: { sizeClass in loggedSizeChanged(sizeClass, for: fishCatch.id) },
                onDetails: { activeSheet = .editCatch(fishCatch) }
            )
        case .pickSpecies:
            NavigationStack {
                SpeciesPickerView(title: "Other fish", allowsUnknown: true, onPick: { species in
                    log(species)
                })
            }
        case .identify:
            IdentifyView(initialImage: nil, onLogged: { fishCatch in
                moveOffStaleTrip(fishCatch)
                showLogged(for: fishCatch)
            })
        case .lastTrip(let trip):
            NavigationStack {
                TripDetailView(trip: trip)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") { activeSheet = nil }
                        }
                    }
            }
        }
    }

    private var endTripMessage: String {
        let fish = activeTrip?.totalFish ?? 0
        if fish == 0 { return "No fish logged on this trip yet." }
        return "\(fish) fish on this trip. You can still edit it later in the Trips tab."
    }

    // MARK: Grid

    private func gridKey(for trip: Trip?) -> TodayGridKey {
        TodayGridKey(
            tripID: trip?.id,
            catchCount: trip?.catches.count ?? 0,
            favourites: settings.favouriteSpeciesIDs,
            regions: settings.homeRegions,
            groups: settings.targetGroups,
            mostLogged: mostLoggedIDs
        )
    }

    /// Fish per species on the trip. A single pass with no sorting, cheap enough for every render.
    private static func counts(for trip: Trip?) -> [String: Int] {
        var counts: [String: Int] = [:]
        for fishCatch in trip?.catches ?? [] {
            counts[fishCatch.speciesID, default: 0] += fishCatch.count
        }
        return counts
    }

    /// Species on the trip in the order they were first caught, so new tiles append in a steady order.
    private static func caughtSpeciesIDs(in trip: Trip) -> [String] {
        var seen = Set<String>()
        var ids: [String] = []
        for fishCatch in trip.catches.sorted(by: { $0.timestamp < $1.timestamp })
        where seen.insert(fishCatch.speciesID).inserted {
            ids.append(fishCatch.speciesID)
        }
        return ids
    }

    /// Keeps the grid steady. A running trip keeps the order it started with and only grows at the
    /// end; with no trip, the grid is ranked fresh from favourites and history.
    private func refreshTiles() {
        let favourites = settings.favouriteSpeciesIDs
        var order = tileOrder
        if let trip = activeTrip {
            if order.tripID != trip.id {
                if order.tripID == nil, !order.speciesIDs.isEmpty {
                    // A trip that just started (from a tile, the start sheet, Siri or another tab)
                    // keeps the tiles the angler was already looking at.
                    order.tripID = trip.id
                } else {
                    order = rankedOrder(for: trip.id)
                }
            }
            let caught = Self.caughtSpeciesIDs(in: trip)
            order.appendMissing(favourites + caught)
            order.trimTrailing(keeping: Set(favourites).union(caught))
        } else if mostLoggedIDs != nil || order.speciesIDs.isEmpty {
            order = rankedOrder(for: nil)
        } else {
            // Keep the last grid until history loads, so the tiles do not shuffle as the tab opens.
            order.tripID = nil
        }
        guard order != tileOrder else { return }
        tileOrder = order
        order.save()
    }

    private func rankedOrder(for tripID: UUID?) -> TodayTileOrder {
        let history: [String]
        if let mostLoggedIDs {
            history = mostLoggedIDs
        } else {
            // Only when a trip is first seen before history loaded; normally the fetch is in .task.
            history = CatchLogger.mostLoggedSpeciesIDs(in: modelContext, limit: TodayTileOrder.maxRankedTiles)
            mostLoggedIDs = history
            historyCache.isStale = false
        }
        let suggested = SpeciesCatalog.suggested(
            regions: settings.homeRegions,
            groups: settings.targetGroups,
            limit: TodayTileOrder.maxRankedTiles
        ).map(\.id)
        return TodayTileOrder.ranked(
            tripID: tripID,
            favourites: settings.favouriteSpeciesIDs,
            mostLogged: history,
            suggested: suggested
        )
    }

    // MARK: Appearing

    /// Once per appearance: history for the idle grid, the idle card, and the stale trip question.
    /// A running trip keeps its tile order, so it skips the history fetch. Coming back to the tab
    /// only fetches history again when something was saved since, because it reads every catch.
    private func screenAppeared() async {
        // Another tab may have deleted the catch the confirmation points at. This runs before the
        // confirmation takes taps again, so Size, Photo and Undo never reach a deleted catch.
        validateLogged()
        if activeTrip == nil {
            if mostLoggedIDs == nil || historyCache.isStale {
                historyCache.isStale = false
                mostLoggedIDs = CatchLogger.mostLoggedSpeciesIDs(in: modelContext, limit: TodayTileOrder.maxRankedTiles)
            }
            loadIdleInfo()
        }
        checkStaleTrip()
        // Catches may have changed species on another tab.
        refreshTiles()
    }

    private func activeTripChanged() {
        refreshActiveTripIfNeeded()
        checkStaleTrip()
        if activeTrip == nil {
            loadIdleInfo()
        }
    }

    /// Two small fetches: today's trips and the newest trip.
    private func loadIdleInfo() {
        let startOfToday = Calendar.current.startOfDay(for: .now)
        let descriptor = FetchDescriptor<Trip>(predicate: #Predicate<Trip> { $0.startDate >= startOfToday })
        let todayTrips = (try? modelContext.fetch(descriptor)) ?? []
        let lastTrip = CatchLogger.latestTrip(in: modelContext)
        idle = TodayIdleInfo(
            summary: TodayIdleCard.summaryText(
                todayTrips: todayTrips.count,
                todayFish: todayTrips.reduce(0) { $0 + $1.totalFish },
                lastTrip: lastTrip
            ),
            lastTrip: lastTrip
        )
    }

    private func sheetDismissed() {
        validateLogged()
        if activeTrip == nil {
            loadIdleInfo()
        }
        // The catch editor can change a species, which may need a new tile at the end.
        refreshTiles()
    }

    // MARK: Logging

    private func log(_ species: Species, count: Int = 1, openDetails: Bool = false) {
        endStaleTripBeforeLogging()
        let fishCatch = CatchLogger.logCatch(speciesID: species.id, count: count, in: modelContext)
        Haptics.logged()
        showLogged(for: fishCatch)
        if openDetails {
            activeSheet = .editCatch(fishCatch)
        }
    }

    private func logAnother(like fishCatch: FishCatch) {
        endStaleTripBeforeLogging()
        let newCatch = CatchLogger.logAnother(like: fishCatch, in: modelContext)
        Haptics.logged()
        showLogged(for: newCatch)
    }

    private func delete(_ fishCatch: FishCatch) {
        if logged?.catchID == fishCatch.id {
            hideLogged()
        }
        CatchLogger.delete(fishCatch, in: modelContext)
        Haptics.warning()
    }

    /// Opening Photo ID leaves a flagged trip alone: only a fish logged there starts a new trip, so
    /// checking a fish and cancelling changes nothing.
    private func openPhotoID() {
        activeSheet = .identify
    }

    // MARK: Ending trips

    /// A trip already flagged as forgotten ends at its last fish, whichever End button is used.
    private func endActiveTrip() {
        guard let trip = activeTrip else { return }
        let date = staleTripID == trip.id ? TodayStaleTripCard.endDate(for: trip) : Date.now
        finishTrip(trip, at: date)
    }

    private func finishTrip(_ trip: Trip, at date: Date) {
        hideLogged()
        CatchLogger.endTrip(trip, in: modelContext, at: date)
        staleTripID = nil
        Haptics.tap()
        // Between trips is the one time the grid re-ranks, so fish caught often move up.
        mostLoggedIDs = CatchLogger.mostLoggedSpeciesIDs(in: modelContext, limit: TodayTileOrder.maxRankedTiles)
        // Fetched after the trip ended, so it is current.
        historyCache.isStale = false
        announce("Trip ended.")
    }

    // MARK: Stale trip

    /// Looked at when the screen appears or the app comes back, never while the angler is tapping.
    private func checkStaleTrip() {
        guard let trip = activeTrip else {
            staleTripID = nil
            return
        }
        let keptGoing = keptGoingTripID == trip.id.uuidString ? Date(timeIntervalSince1970: keptGoingAt) : nil
        staleTripID = TodayStaleTripCard.isStale(trip, keptGoingAt: keptGoing) ? trip.id : nil
    }

    private func endStaleTrip(_ trip: Trip) {
        finishTrip(trip, at: TodayStaleTripCard.endDate(for: trip))
    }

    private func keepGoing(_ trip: Trip) {
        keptGoingTripID = trip.id.uuidString
        keptGoingAt = Date.now.timeIntervalSince1970
        staleTripID = nil
    }

    /// The card says logging starts a new trip: the forgotten one ends at its last fish, and the new
    /// trip keeps the tiles exactly where they are.
    private func endStaleTripBeforeLogging() {
        guard let trip = activeTrip else { return }
        if staleTripID == trip.id {
            CatchLogger.endTrip(trip, in: modelContext, at: TodayStaleTripCard.endDate(for: trip))
            staleTripID = nil
            tileOrder.tripID = nil
        } else if CatchLogger.isForgotten(trip) {
            // Gone quiet while this screen stayed open: logCatch closes it and starts a new trip by
            // itself, and the tiles should stay put for that one too.
            tileOrder.tripID = nil
        }
    }

    /// Photo ID saves its catch itself, so the flagged trip cannot end before the fish goes in. A
    /// fish that landed on it moves to a new trip, as the card says, and the forgotten trip ends at
    /// its last earlier fish. The new trip keeps the tiles where they are.
    private func moveOffStaleTrip(_ fishCatch: FishCatch) {
        guard let staleID = staleTripID else { return }
        staleTripID = nil
        tileOrder.tripID = nil
        // Logging may already have ended a long quiet trip and started a new one by itself.
        guard let stale = fishCatch.trip, stale.id == staleID, stale.isActive else { return }
        let catchID = fishCatch.id
        let lastEarlierFish = stale.catches.filter { $0.id != catchID }.map(\.timestamp).max()
        CatchLogger.endTrip(stale, in: modelContext, at: lastEarlierFish ?? stale.startDate)
        let trip = CatchLogger.startTrip(
            in: modelContext,
            waterBody: stale.waterBody,
            method: stale.method,
            at: fishCatch.timestamp
        )
        fishCatch.trip = trip
        CatchLogger.save(modelContext)
    }

    // MARK: Logged confirmation

    private var loggedTransition: AnyTransition {
        reduceMotion ? AnyTransition.opacity : AnyTransition.move(edge: .top).combined(with: .opacity)
    }

    private func showLogged(for fishCatch: FishCatch) {
        let name = fishCatch.speciesName
        let title = fishCatch.count > 1 ? "\(fishCatch.count) \(name.lowercased()) logged" : "\(name) logged"
        let speciesID = fishCatch.speciesID
        var sameSpecies = fishCatch.count
        if let trip = fishCatch.trip {
            sameSpecies = trip.catches
                .filter { $0.speciesID == speciesID }
                .reduce(0) { $0 + $1.count }
        }
        let info = TodayLoggedInfo(
            catchID: fishCatch.id,
            token: UUID(),
            title: title,
            subtitle: "\(sameSpecies) this trip",
            species: fishCatch.species,
            sizeLabel: fishCatch.sizeClass?.label,
            hasPhoto: !fishCatch.photos.isEmpty
        )
        loggedCatch = fishCatch
        loggedStartedTrip = Self.tripStarted(by: fishCatch)
        logged = info
        announce("\(title). \(info.subtitle).")
    }

    /// The trip this log started, if it did. A trip started by logging begins at the catch's own
    /// time, whether it came from a tile, Another one, Photo ID, or after a forgotten trip ended. One
    /// started by hand always begins earlier.
    private static func tripStarted(by fishCatch: FishCatch) -> Trip? {
        guard let trip = fishCatch.trip, trip.isActive, trip.startDate == fishCatch.timestamp else { return nil }
        return trip
    }

    private func hideLogged() {
        logged = nil
        loggedCatch = nil
        loggedStartedTrip = nil
    }

    /// The catch the confirmation points at, or nil once it is gone. Reading a deleted model can crash.
    private var liveLoggedCatch: FishCatch? {
        guard let fishCatch = loggedCatch, !fishCatch.isDeleted, fishCatch.modelContext != nil else { return nil }
        return fishCatch
    }

    /// Puts things back the way they were. A trip this log started that now holds nothing goes too,
    /// so a stray tap does not leave a trip running with GPS on.
    private func undoLastLog() {
        guard let fishCatch = liveLoggedCatch else {
            hideLogged()
            return
        }
        let startedTrip = loggedStartedTrip
        hideLogged()
        CatchLogger.delete(fishCatch, in: modelContext)
        if let trip = startedTrip, !trip.isDeleted, trip.modelContext != nil, trip.isActive,
           !trip.catches.contains(where: { !$0.isDeleted && $0.modelContext != nil }) {
            // Also stops GPS and the barometer, because the trip is still running.
            CatchLogger.delete(trip, in: modelContext)
        }
        Haptics.warning()
        announce("Catch removed.")
    }

    private func openSize() {
        guard let fishCatch = liveLoggedCatch else {
            hideLogged()
            return
        }
        activeSheet = .setSize(fishCatch)
    }

    private func loggedSizeChanged(_ sizeClass: SizeClass?, for catchID: UUID) {
        guard logged?.catchID == catchID else { return }
        logged?.sizeLabel = sizeClass?.label
    }

    /// The catch editor can delete the catch the confirmation points at, so check before touching it again.
    private func validateLogged() {
        guard let info = logged else { return }
        let targetID = info.catchID
        let descriptor = FetchDescriptor<FishCatch>(predicate: #Predicate<FishCatch> { $0.id == targetID })
        let stillThere = ((try? modelContext.fetchCount(descriptor)) ?? 0) > 0
        guard stillThere, let fishCatch = liveLoggedCatch else {
            hideLogged()
            return
        }
        logged?.sizeLabel = fishCatch.sizeClass?.label
        logged?.hasPhoto = logged?.hasPhoto == true || !fishCatch.photos.isEmpty
    }

    // MARK: Photo for the fish just logged

    /// Camera when the phone has one, the photo library otherwise.
    private func openPhoto() {
        guard let fishCatch = liveLoggedCatch else {
            hideLogged()
            return
        }
        photoTarget = fishCatch
        if CameraPicker.isAvailable {
            showingCamera = true
        } else {
            showingPhotoPicker = true
        }
    }

    private func attachPhoto(_ image: UIImage) {
        guard let fishCatch = photoTarget else { return }
        photoTarget = nil
        guard !fishCatch.isDeleted, fishCatch.modelContext != nil else { return }
        let photosBefore = fishCatch.photos.count
        let context = modelContext
        Task {
            await CatchLogger.attachPhoto(image, to: fishCatch, in: context)
            photoAttached(to: fishCatch, photosBefore: photosBefore)
        }
    }

    private func attachPickedPhoto(_ item: PhotosPickerItem) {
        guard let fishCatch = photoTarget else { return }
        photoTarget = nil
        guard !fishCatch.isDeleted, fishCatch.modelContext != nil else { return }
        let photosBefore = fishCatch.photos.count
        let context = modelContext
        Task {
            guard let data = try? await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else { return }
            await CatchLogger.attachPhoto(image, to: fishCatch, in: context)
            photoAttached(to: fishCatch, photosBefore: photosBefore)
        }
    }

    /// attachPhoto quietly skips a catch deleted while the photo was encoding, and a photo that would
    /// not encode, so only a photo that is really there gets the checkmark.
    private func photoAttached(to fishCatch: FishCatch, photosBefore: Int) {
        guard !fishCatch.isDeleted, fishCatch.modelContext != nil,
              logged?.catchID == fishCatch.id,
              fishCatch.photos.count > photosBefore
        else { return }
        logged?.hasPhoto = true
        announce("Photo added.")
    }

    private func announce(_ message: String) {
        guard UIAccessibility.isVoiceOverRunning else { return }
        UIAccessibility.post(notification: .announcement, argument: message)
    }

    // MARK: Conditions

    /// Trips started by the first tap on a tile skip the start sheet, so they get their conditions here.
    private func refreshActiveTripIfNeeded() {
        guard let trip = activeTrip, !refreshedTripIDs.contains(trip.id), !isFetchingWeather else { return }
        refreshedTripIDs.insert(trip.id)
        let needsName = trip.locationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let needsWeather = settings.autoFetchWeather && trip.weatherFetchedAt == nil
        guard needsName || needsWeather || trip.coordinate == nil else { return }
        fetchWeather(for: trip)
    }

    /// Unstructured on purpose: switching tabs should not cancel a weather lookup halfway.
    private func fetchWeather(for trip: Trip) {
        guard !isFetchingWeather else { return }
        isFetchingWeather = true
        let context = modelContext
        Task {
            await TripConditionsUpdater.refresh(trip, in: context)
            isFetchingWeather = false
        }
    }
}
