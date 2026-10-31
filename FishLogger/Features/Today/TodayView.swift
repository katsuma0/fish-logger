import SwiftData
import SwiftUI
import UIKit

/// Everything a sheet on the Today screen can show. One `.sheet(item:)` keeps presentations from
/// fighting each other when a tile, the banner, and the trip list all want to open something.
enum TodaySheet: Identifiable {
    case startTrip
    case editTrip(Trip)
    case editCatch(FishCatch)
    case pickSpecies
    case identify(UIImage?)

    var id: String {
        switch self {
        case .startTrip:
            return "startTrip"
        case .editTrip(let trip):
            return "editTrip-\(trip.id.uuidString)"
        case .editCatch(let fishCatch):
            return "editCatch-\(fishCatch.id.uuidString)"
        case .pickSpecies:
            return "pickSpecies"
        case .identify(let image):
            return image == nil ? "identify" : "identify-photo"
        }
    }
}

/// The on-the-water screen. One tap logs a fish, so everything else stays out of the way.
struct TodayView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: \Trip.startDate, order: .reverse) private var trips: [Trip]

    @State private var activeSheet: TodaySheet?
    @State private var showingCamera = false
    @State private var capturedImage: UIImage?
    @State private var showingEndConfirmation = false
    @State private var bannerInfo: TodayLoggedInfo?
    @State private var bannerCatch: FishCatch?
    @State private var bannerSizeClass: SizeClass?
    @State private var bannerToken = UUID()
    @State private var mostLoggedIDs: [String] = []
    @State private var refreshedTripIDs: Set<UUID> = []
    @State private var isFetchingWeather = false

    /// Common Ontario catches, so a brand new install still has a useful grid.
    private static let defaultSpeciesIDs = [
        "walleye", "smallmouth_bass", "largemouth_bass", "northern_pike", "yellow_perch",
        "black_crappie", "pumpkinseed", "bluegill", "rock_bass", "rainbow_trout",
        "lake_trout", "brook_trout", "muskellunge"
    ]
    private static let maxSpeciesTiles = 12
    private static let bannerSeconds: UInt64 = 8

    private var activeTrip: Trip? { trips.first { $0.endDate == nil } }

    var body: some View {
        NavigationStack {
            ScrollView {
                scrollContent
            }
            .background(Theme.screenBackground)
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if activeTrip != nil {
                        Button("End trip") {
                            showingEndConfirmation = true
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                bottomBar
            }
            .confirmationDialog("End this trip?", isPresented: $showingEndConfirmation, titleVisibility: .visible) {
                Button("End trip") { endActiveTrip() }
                Button("Keep fishing", role: .cancel) {}
            } message: {
                Text(endTripMessage)
            }
        }
        .onAppear {
            LocationService.shared.requestPermission()
            mostLoggedIDs = CatchLogger.mostLoggedSpeciesIDs(in: modelContext, limit: Self.maxSpeciesTiles)
        }
        .onChange(of: activeTrip?.id.uuidString, initial: true) {
            refreshActiveTripIfNeeded()
        }
        .task(id: bannerToken) {
            await autoHideBanner()
        }
        .sheet(item: $activeSheet, onDismiss: { validateBanner() }) { sheet in
            sheetContent(for: sheet)
                .environment(settings)
        }
        .fullScreenCover(isPresented: $showingCamera, onDismiss: { presentCapturedPhoto() }) {
            CameraPicker(onCapture: { image in
                capturedImage = image
                showingCamera = false
            })
            .ignoresSafeArea()
        }
    }

    // MARK: Sections

    private var scrollContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let trip = activeTrip {
                TodayTripHeader(
                    trip: trip,
                    isFetchingWeather: isFetchingWeather,
                    onEdit: { activeSheet = .editTrip(trip) },
                    onGetWeather: { fetchWeather(for: trip) }
                )
            } else {
                idleSection
            }

            quickLogSection

            if let trip = activeTrip, !trip.catches.isEmpty {
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

    private var idleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            TodayIdleCard(trips: trips)
            Button {
                activeSheet = .startTrip
            } label: {
                Label("Start fishing", systemImage: "figure.fishing")
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .accessibilityHint("Pick the spot and start a trip")
        }
    }

    private var quickLogSection: some View {
        let trip = activeTrip
        return VStack(alignment: .leading, spacing: 10) {
            Text("Log a fish")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            if trip == nil {
                Text("Tap a fish to log it. A trip starts on its own.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            TodayQuickLogGrid(
                species: quickLogSpecies(for: trip),
                counts: tripCounts(for: trip),
                onLog: { species, count in log(species, count: count) },
                onLogWithDetails: { species in log(species, openDetails: true) },
                onOtherFish: { activeSheet = .pickSpecies },
                onPhotoID: { startPhotoID() }
            )
        }
    }

    private var bottomBar: some View {
        VStack(alignment: settings.leftHanded ? HorizontalAlignment.leading : HorizontalAlignment.trailing, spacing: 10) {
            TodayCameraButton(action: { startPhotoID() })
                .contextMenu {
                    Button {
                        activeSheet = .identify(nil)
                    } label: {
                        Label("Choose from photos", systemImage: "photo.on.rectangle")
                    }
                }
                .accessibilityAction(named: Text("Choose from photos")) { activeSheet = .identify(nil) }
            if let info = bannerInfo {
                TodayLoggedBanner(
                    info: info,
                    sizeClass: bannerSizeClassBinding,
                    onDetails: { openBannerDetails() },
                    onUndo: { undoLastLog() }
                )
                .transition(bannerTransition)
            }
        }
        .frame(maxWidth: .infinity, alignment: settings.leftHanded ? Alignment.leading : Alignment.trailing)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    @ViewBuilder
    private func sheetContent(for sheet: TodaySheet) -> some View {
        switch sheet {
        case .startTrip:
            TodayStartTripSheet(lastTrip: trips.first, onStart: { trip in
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
        case .pickSpecies:
            NavigationStack {
                SpeciesPickerView(title: "Other fish", allowsUnknown: true, onPick: { species in
                    log(species)
                })
            }
        case .identify(let image):
            IdentifyView(initialImage: image, onLogged: { fishCatch in
                showBanner(for: fishCatch)
            })
        }
    }

    // MARK: Grid contents

    /// This trip's species first, then pinned, then the angler's usual catches, then the Ontario defaults.
    private func quickLogSpecies(for trip: Trip?) -> [Species] {
        var candidates: [String] = []
        if let trip {
            candidates.append(contentsOf: trip.speciesTally.map { $0.speciesID })
        }
        candidates.append(contentsOf: settings.favouriteSpeciesIDs)
        candidates.append(contentsOf: mostLoggedIDs)
        candidates.append(contentsOf: Self.defaultSpeciesIDs)

        var seen = Set<String>()
        var result: [Species] = []
        for id in candidates {
            if result.count >= Self.maxSpeciesTiles { break }
            guard id != SpeciesCatalog.unknownID, seen.insert(id).inserted else { continue }
            guard let species = SpeciesCatalog.species(id: id) else { continue }
            result.append(species)
        }
        return result
    }

    private func tripCounts(for trip: Trip?) -> [String: Int] {
        var counts: [String: Int] = [:]
        guard let trip else { return counts }
        for entry in trip.speciesTally {
            counts[entry.speciesID] = entry.count
        }
        return counts
    }

    private var endTripMessage: String {
        let fish = activeTrip?.totalFish ?? 0
        if fish == 0 { return "No fish logged on this trip yet." }
        return "\(fish) fish on this trip. You can still edit it later in the Log tab."
    }

    // MARK: Logging

    private func log(_ species: Species, count: Int = 1, openDetails: Bool = false) {
        let fishCatch = CatchLogger.logCatch(speciesID: species.id, count: count, in: modelContext)
        Haptics.logged()
        showBanner(for: fishCatch)
        if openDetails {
            activeSheet = .editCatch(fishCatch)
        }
    }

    private func logAnother(like fishCatch: FishCatch) {
        let newCatch = CatchLogger.logAnother(like: fishCatch, in: modelContext)
        Haptics.logged()
        showBanner(for: newCatch)
    }

    private func delete(_ fishCatch: FishCatch) {
        if bannerInfo?.catchID == fishCatch.id {
            hideBanner()
        }
        CatchLogger.delete(fishCatch, in: modelContext)
        Haptics.warning()
    }

    private func endActiveTrip() {
        guard let trip = activeTrip else { return }
        hideBanner()
        CatchLogger.endTrip(trip, in: modelContext)
        Haptics.tap()
        mostLoggedIDs = CatchLogger.mostLoggedSpeciesIDs(in: modelContext, limit: Self.maxSpeciesTiles)
    }

    // MARK: Banner

    private var bannerTransition: AnyTransition {
        reduceMotion ? AnyTransition.opacity : AnyTransition.move(edge: .bottom).combined(with: .opacity)
    }

    private var bannerSizeClassBinding: Binding<SizeClass?> {
        Binding<SizeClass?>(
            get: { bannerSizeClass },
            set: { newValue in
                bannerSizeClass = newValue
                if let fishCatch = bannerCatch {
                    fishCatch.sizeClass = newValue
                    CatchLogger.save(modelContext)
                }
                bannerToken = UUID()
            }
        )
    }

    private func showBanner(for fishCatch: FishCatch) {
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
            title: title,
            subtitle: "\(sameSpecies) this trip",
            species: fishCatch.species
        )
        bannerCatch = fishCatch
        bannerSizeClass = fishCatch.sizeClass
        withAnimation(.easeOut(duration: 0.25)) {
            bannerInfo = info
        }
        bannerToken = UUID()
        if UIAccessibility.isVoiceOverRunning {
            UIAccessibility.post(notification: .announcement, argument: "\(title). \(info.subtitle).")
        }
    }

    private func hideBanner() {
        withAnimation(.easeInOut(duration: 0.25)) {
            bannerInfo = nil
        }
        bannerCatch = nil
    }

    private func autoHideBanner() async {
        guard bannerInfo != nil else { return }
        try? await Task.sleep(nanoseconds: Self.bannerSeconds * 1_000_000_000)
        guard !Task.isCancelled else { return }
        hideBanner()
    }

    private func undoLastLog() {
        guard let fishCatch = bannerCatch else {
            hideBanner()
            return
        }
        hideBanner()
        CatchLogger.delete(fishCatch, in: modelContext)
        Haptics.warning()
    }

    private func openBannerDetails() {
        guard let fishCatch = bannerCatch else { return }
        bannerToken = UUID()
        activeSheet = .editCatch(fishCatch)
    }

    /// The catch editor can delete the catch the banner points at, so check before touching it again.
    private func validateBanner() {
        guard let info = bannerInfo else { return }
        let targetID = info.catchID
        let descriptor = FetchDescriptor<FishCatch>(predicate: #Predicate<FishCatch> { $0.id == targetID })
        let stillThere = ((try? modelContext.fetchCount(descriptor)) ?? 0) > 0
        if stillThere {
            bannerSizeClass = bannerCatch?.sizeClass
            bannerToken = UUID()
        } else {
            hideBanner()
        }
    }

    // MARK: Photo ID

    private func startPhotoID() {
        Haptics.tap()
        if CameraPicker.isAvailable {
            showingCamera = true
        } else {
            activeSheet = .identify(nil)
        }
    }

    private func presentCapturedPhoto() {
        guard let image = capturedImage else { return }
        capturedImage = nil
        activeSheet = .identify(image)
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
