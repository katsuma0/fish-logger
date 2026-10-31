import PhotosUI
import SwiftData
import SwiftUI
import UIKit

/// Screens IdentifyView can push.
private enum IdentifyRoute: Hashable {
    case checklist
    case confirm(speciesID: String, source: IdentificationSource)
    /// The Photo ID settings page, pushed here so a key can be added or fixed without losing the photo.
    case photoIDSettings
}

/// Which engine looks at the photo.
private enum IdentifyEngine {
    case claude
    case onDevice

    var progressMessage: String {
        switch self {
        case .claude: return "Looking at the fish"
        case .onDevice: return "Checking the photo on this phone"
        }
    }
}

/// Where Photo ID stands for the current photo.
private enum IdentifyPhase {
    /// Photo is in, nothing has run. With Claude set up, this is where the Identify button waits.
    case idle
    case running(String)
    case finished(IdentificationResult)
    case failed(IdentificationError)
    /// No engine can look at photos on this phone, so the checklist is the way.
    case needsChecklist
}

/// Photo to species to logged catch. Presented in a sheet; owns its NavigationStack.
/// A photo only goes to Anthropic when the person taps Identify, with photo ID on and a key saved.
/// The on-device model, when bundled, and the checklist run on their own because nothing leaves
/// the phone.
struct IdentifyView: View {
    let initialImage: UIImage?
    let onLogged: ((FishCatch) -> Void)?

    @Environment(AppSettings.self) private var settings
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    /// The original, for identifying and saving. Never drawn on screen.
    @State private var image: UIImage?
    /// Small decoded copy for the preview and the confirm screen, made in the background.
    @State private var displayImage: UIImage?
    /// File data for a library photo, which saves more cheaply than the decoded image.
    @State private var photoData: Data?
    /// Bumped for each new photo, so late work for an older photo is dropped.
    @State private var photoID = 0
    @State private var phase: IdentifyPhase = .idle
    @State private var lastEngine: IdentifyEngine = .claude
    @State private var runTask: Task<Void, Never>?
    /// Bumped for each run, so an answer that arrives after a newer run started is ignored.
    @State private var runID = 0
    @State private var path: [IdentifyRoute] = []
    @State private var hasAPIKey = false
    @State private var keyChecked = false
    @State private var showingCamera = false
    @State private var photoItem: PhotosPickerItem? = nil
    @State private var isLoadingPhoto = false
    @State private var photoLoadFailed = false
    @State private var showingSpeciesPicker = false
    @State private var pendingManualPickID: String? = nil
    /// Set on the first log so a queued second tap cannot log the fish twice.
    @State private var hasLogged = false

    init(initialImage: UIImage? = nil, onLogged: ((FishCatch) -> Void)? = nil) {
        self.initialImage = initialImage
        self.onLogged = onLogged
        _image = State(initialValue: initialImage)
    }

    var body: some View {
        NavigationStack(path: $path) {
            rootList
                .navigationTitle("Photo ID")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            cancelRun()
                            dismiss()
                        }
                    }
                }
                .navigationDestination(for: IdentifyRoute.self) { route in
                    destination(for: route)
                }
        }
        .onAppear {
            refreshKeyState()
            // A photo handed in by the caller gets the same treatment as one taken here, once.
            if let image, photoID == 0 {
                photoID = 1
                makeDisplayCopy(of: image, for: photoID)
                startAutomaticEngines()
            }
        }
        // Closing the sheet mid-request stops it. The camera cover also hides this view, so it is skipped then.
        .onDisappear {
            if !showingCamera { cancelRun() }
        }
        .onChange(of: photoItem) { _, newItem in
            guard let newItem else { return }
            loadPhoto(from: newItem)
        }
        .onChange(of: path) { oldPath, newPath in
            if oldPath.contains(.photoIDSettings), !newPath.contains(.photoIDSettings) {
                returnedFromSettings()
            }
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraPicker(onCapture: { captured in
                useImage(captured)
            })
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showingSpeciesPicker, onDismiss: { openPendingManualPick() }) {
            NavigationStack {
                SpeciesPickerView(title: "Pick a species", allowsUnknown: true, onPick: { species in
                    pendingManualPickID = species.id
                })
            }
            .environment(settings)
        }
    }

    // MARK: Root screen

    private var rootList: some View {
        List {
            if let image {
                photoSection(image)
                statusSections
                if showsSetupNoteSection, let setupError {
                    Section {
                        Label(setupError.message, systemImage: "key")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        settingsRow(for: setupError)
                    }
                }
            } else {
                startSections
            }
        }
        .listStyle(.insetGrouped)
    }

    @ViewBuilder
    private var startSections: some View {
        Section {
            VStack(spacing: 10) {
                Image(systemName: "camera.viewfinder")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                Text("Get the whole fish in the frame, side on, in good light.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }

        Section {
            if CameraPicker.isAvailable {
                Button {
                    showingCamera = true
                } label: {
                    Label("Take a photo", systemImage: "camera.fill")
                }
                .buttonStyle(PrimaryActionButtonStyle())
                .modifier(IdentifyClearRow())

                PhotosPicker(selection: $photoItem, matching: .images) {
                    Label("Choose a photo", systemImage: "photo.on.rectangle")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: settings.buttonSize.minTapSize)
                }
                .buttonStyle(.bordered)
                .modifier(IdentifyClearRow())
            } else {
                PhotosPicker(selection: $photoItem, matching: .images) {
                    Label("Choose a photo", systemImage: "photo.on.rectangle")
                }
                .buttonStyle(PrimaryActionButtonStyle())
                .modifier(IdentifyClearRow())
            }

            photoStatusRows
        } footer: {
            if keyChecked, claudeReady {
                Text("Nothing leaves your iPhone until you tap Identify.")
            }
        }

        Section {
            Button {
                path.append(.checklist)
            } label: {
                Label("Use the checklist instead", systemImage: "checklist")
                    .frame(minHeight: settings.buttonSize.minTapSize)
            }
            if keyChecked, let setupError {
                settingsRow(for: setupError)
            }
        } footer: {
            if keyChecked, let note = setupNote {
                Text(note)
            }
        }
    }

    private func photoSection(_ image: UIImage) -> some View {
        Section {
            photoPreview(for: image)
                .modifier(IdentifyClearRow())

            HStack(spacing: 12) {
                if CameraPicker.isAvailable {
                    Button {
                        showingCamera = true
                    } label: {
                        Label("Retake", systemImage: "camera")
                            .frame(maxWidth: .infinity, minHeight: settings.buttonSize.minTapSize)
                    }
                    .buttonStyle(.bordered)
                }
                PhotosPicker(selection: $photoItem, matching: .images) {
                    Label("Choose another", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity, minHeight: settings.buttonSize.minTapSize)
                }
                .buttonStyle(.bordered)
            }
            .modifier(IdentifyClearRow())

            photoStatusRows
        }
    }

    /// Draws only the display copy. Until it is ready, a placeholder with the photo's shape holds
    /// the space so the buttons below do not jump.
    @ViewBuilder
    private func photoPreview(for image: UIImage) -> some View {
        if let displayImage {
            Image(uiImage: displayImage)
                .resizable()
                .scaledToFit()
                // Colour is half of an ID, so Smart Invert must not flip the photo.
                .accessibilityIgnoresInvertColors()
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
                .frame(maxWidth: .infinity, maxHeight: 280)
                .accessibilityLabel("Your photo")
        } else {
            let size = image.size
            let ratio = size.height > 0 ? size.width / size.height : 1
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .fill(Color(uiColor: .tertiarySystemFill))
                .aspectRatio(ratio, contentMode: .fit)
                .overlay(ProgressView())
                .frame(maxWidth: .infinity, maxHeight: 280)
                .accessibilityLabel("Your photo, loading")
        }
    }

    @ViewBuilder
    private var photoStatusRows: some View {
        if isLoadingPhoto {
            loadingRow("Opening the photo")
        } else if photoLoadFailed {
            Label(IdentificationError.imageUnreadable.message, systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var statusSections: some View {
        switch phase {
        case .idle:
            if claudeReady {
                identifySections
            }

        case .running(let message):
            Section {
                loadingRow(message)
            }

        case .failed(let error):
            Section {
                Label(error.message, systemImage: "exclamationmark.triangle.fill")
                    .fixedSize(horizontal: false, vertical: true)
                // Only where a second send can work. A bad key or a refused photo fails the same way again.
                if error.isRetryable {
                    actionRow("Try again", systemImage: "arrow.clockwise") {
                        start(lastEngine)
                    }
                }
                if error.needsSetup {
                    settingsRow(for: error)
                }
                if lastEngine == .claude, OnDeviceIdentifier.isAvailable {
                    actionRow("Use the on-device model", systemImage: "iphone") {
                        start(.onDevice)
                    }
                }
                checklistRow
                pickFromListRow
            }

        case .finished(let result):
            resultSections(result)

        case .needsChecklist:
            Section {
                Text(setupNote ?? "Work it out from what you can see.")
                    .fixedSize(horizontal: false, vertical: true)
                Button {
                    path.append(.checklist)
                } label: {
                    Label("Use the checklist", systemImage: "checklist")
                }
                .buttonStyle(PrimaryActionButtonStyle())
                .modifier(IdentifyClearRow())
                pickFromListRow
                if let setupError {
                    settingsRow(for: setupError)
                }
            }
        }
    }

    /// The one place a photo is sent to Claude.
    @ViewBuilder
    private var identifySections: some View {
        Section {
            Button {
                start(.claude)
            } label: {
                Label("Identify", systemImage: "magnifyingglass")
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .modifier(IdentifyClearRow())
            .accessibilityHint("Sends this photo to Claude and suggests the species")
        } footer: {
            Text("Sends this photo to Anthropic. Each ID costs a few cents on your API account.")
        }

        Section {
            checklistRow
            pickFromListRow
        }
    }

    @ViewBuilder
    private func resultSections(_ result: IdentificationResult) -> some View {
        Section {
            if !result.isFish {
                Text("That does not look like a fish. Try another photo, or use the checklist.")
                    .fixedSize(horizontal: false, vertical: true)
            } else if result.candidates.isEmpty {
                Text("No clear match. Try the checklist, or pick from the list.")
                    .fixedSize(horizontal: false, vertical: true)
            }
            ForEach(result.candidates) { candidate in
                NavigationLink(value: IdentifyRoute.confirm(speciesID: candidate.speciesID, source: result.source)) {
                    IdentifyCandidateRow(candidate: candidate)
                }
            }
        } header: {
            Text(resultsHeader(for: result))
        } footer: {
            if !result.photoNotes.isEmpty {
                Text(result.photoNotes)
            }
        }

        Section {
            pickFromListRow
            checklistRow
            // Only after the on-device model answered; Claude still waits for a tap.
            if result.source == .onDevice, claudeReady {
                actionRow("Identify with Claude", systemImage: "magnifyingglass") {
                    start(.claude)
                }
            }
        }
    }

    private func resultsHeader(for result: IdentificationResult) -> String {
        result.source == .onDevice ? "Best matches, on this phone" : "Best matches"
    }

    // MARK: Rows

    private func loadingRow(_ message: String) -> some View {
        HStack(spacing: 12) {
            ProgressView()
            Text(message)
                .foregroundStyle(.secondary)
        }
        .frame(minHeight: settings.buttonSize.minTapSize)
        .accessibilityElement(children: .combine)
    }

    private func actionRow(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .frame(minHeight: settings.buttonSize.minTapSize)
        }
    }

    private var checklistRow: some View {
        actionRow("Use the checklist", systemImage: "checklist") {
            path.append(.checklist)
        }
    }

    private var pickFromListRow: some View {
        actionRow("Not it? Pick from the list", systemImage: "list.bullet") {
            showingSpeciesPicker = true
        }
    }

    /// Opens the Photo ID settings page on top of this screen, so the photo is still here after the
    /// key is fixed.
    private func settingsRow(for error: IdentificationError) -> some View {
        actionRow(settingsRowTitle(for: error), systemImage: "key") {
            path.append(.photoIDSettings)
        }
    }

    private func settingsRowTitle(for error: IdentificationError) -> String {
        switch error {
        case .notConfigured: return "Add your API key"
        case .photoIDDisabled: return "Turn on Photo ID"
        case .invalidAPIKey: return "Check your API key"
        default: return "Open Photo ID settings"
        }
    }

    // MARK: Destinations

    @ViewBuilder
    private func destination(for route: IdentifyRoute) -> some View {
        switch route {
        case .checklist:
            TraitKeyView(
                onPick: { species in
                    path.append(.confirm(speciesID: species.id, source: .traitKey))
                },
                onPickByName: {
                    showingSpeciesPicker = true
                }
            )
        case .confirm(let speciesID, let source):
            IdentifyConfirmView(
                species: SpeciesCatalog.species(id: speciesID) ?? SpeciesCatalog.unknown,
                photo: displayImage,
                source: source,
                onLog: { sizeClass, count in
                    log(speciesID: speciesID, source: source, sizeClass: sizeClass, count: count)
                }
            )
        case .photoIDSettings:
            SettingsPhotoIDView()
        }
    }

    // MARK: Setup

    private var claudeReady: Bool { settings.photoIDEnabled && hasAPIKey }

    /// What stops Claude from running, if anything. Both are fixed on the Photo ID settings page.
    private var setupError: IdentificationError? {
        if !hasAPIKey { return .notConfigured }
        if !settings.photoIDEnabled { return .photoIDDisabled }
        return nil
    }

    private var setupNote: String? { setupError?.message }

    /// The needs-checklist section, or a failure that already offers the settings page, says it
    /// already, so the separate note would repeat it.
    private var showsSetupNoteSection: Bool {
        guard keyChecked, !claudeReady else { return false }
        switch phase {
        case .needsChecklist:
            return false
        case .failed(let error):
            return !error.needsSetup
        case .idle, .running, .finished:
            return true
        }
    }

    private func refreshKeyState() {
        hasAPIKey = KeychainStore.hasValue(for: .anthropicAPIKey)
        keyChecked = true
    }

    /// Back from the Photo ID settings page. A failed or waiting photo starts over so a fixed key
    /// shows the Identify button again. Never sends the photo itself: with Claude ready,
    /// `startAutomaticEngines` returns at once and the screen waits for a tap. Results that are
    /// already showing stay, and an on-device result picks up "Identify with Claude" from the new key.
    private func returnedFromSettings() {
        refreshKeyState()
        guard image != nil else { return }
        switch phase {
        case .failed, .needsChecklist, .idle:
            cancelRun()
            phase = .idle
            startAutomaticEngines()
        case .running, .finished:
            break
        }
    }

    // MARK: Actions

    private func useImage(_ newImage: UIImage, fileData: Data? = nil, display: UIImage? = nil) {
        cancelRun()
        photoID += 1
        image = newImage
        photoData = fileData
        displayImage = display
        photoLoadFailed = false
        phase = .idle
        path.removeAll()
        if display == nil {
            makeDisplayCopy(of: newImage, for: photoID)
        }
        refreshKeyState()
        startAutomaticEngines()
    }

    private func makeDisplayCopy(of source: UIImage, for id: Int) {
        Task {
            let copy = await IdentifyDisplayImage.make(from: source)
            guard id == photoID else { return }
            displayImage = copy
        }
    }

    /// Only the paths that keep the photo on the phone start by themselves. With Claude set up,
    /// the screen waits for Identify instead.
    private func startAutomaticEngines() {
        guard !claudeReady else { return }
        if OnDeviceIdentifier.isAvailable {
            start(.onDevice)
        } else {
            phase = .needsChecklist
        }
    }

    private func loadPhoto(from item: PhotosPickerItem) {
        isLoadingPhoto = true
        photoLoadFailed = false
        Task {
            let data = try? await item.loadTransferable(type: Data.self)
            // Cleared so picking the same photo again still counts as a change.
            photoItem = nil
            guard let data, let prepared = await IdentifyDisplayImage.prepare(fileData: data) else {
                isLoadingPhoto = false
                photoLoadFailed = true
                Haptics.warning()
                return
            }
            isLoadingPhoto = false
            useImage(prepared.full, fileData: data, display: prepared.display)
        }
    }

    private func openPendingManualPick() {
        guard let speciesID = pendingManualPickID else { return }
        pendingManualPickID = nil
        path.append(.confirm(speciesID: speciesID, source: .manual))
    }

    /// Logs right away and closes the sheet. The photo is encoded and attached in the background,
    /// so the tap never waits on it.
    private func log(speciesID: String, source: IdentificationSource, sizeClass: SizeClass?, count: Int) {
        guard !hasLogged else { return }
        hasLogged = true
        cancelRun()
        let fileData = photoData
        let fishCatch = CatchLogger.logCatch(
            speciesID: speciesID,
            count: count,
            sizeClass: sizeClass,
            photo: fileData == nil ? image : nil,
            identifiedBy: source,
            in: modelContext
        )
        if let fileData {
            // Library photos keep their file data, which ImageIO downsamples without a full decode.
            let context = modelContext
            Task {
                await CatchLogger.attachPhoto(data: fileData, to: fishCatch, in: context)
            }
        }
        Haptics.logged()
        onLogged?(fishCatch)
        dismiss()
    }

    // MARK: Identification

    private func cancelRun() {
        runTask?.cancel()
        runTask = nil
        runID += 1
    }

    private func start(_ engine: IdentifyEngine) {
        guard let image else { return }
        runTask?.cancel()
        runID += 1
        let id = runID
        lastEngine = engine

        var apiKey = ""
        if engine == .claude {
            // Read fresh: the key may have been removed in Settings since this screen opened.
            guard let saved = KeychainStore.string(for: .anthropicAPIKey), settings.photoIDEnabled else {
                refreshKeyState()
                let error: IdentificationError = hasAPIKey ? .photoIDDisabled : .notConfigured
                phase = .failed(error)
                announce(.failed(error))
                return
            }
            apiKey = saved
        }
        let model = settings.claudeModel
        let regions = settings.homeRegions
        phase = .running(engine.progressMessage)
        // The button that was tapped is gone, so say the work has started.
        IdentifyAnnouncement.post(engine.progressMessage)

        runTask = Task {
            let outcome = await Self.identify(image, engine: engine, apiKey: apiKey, model: model, regions: regions)
            // A cancelled or superseded run leaves the screen as the newer action set it.
            guard let outcome, !Task.isCancelled, id == runID else { return }
            phase = outcome
            announce(outcome)
            if case .failed = outcome { Haptics.warning() }
        }
    }

    /// The results replace the loading row without moving VoiceOver focus, so the outcome is spoken.
    private func announce(_ outcome: IdentifyPhase) {
        switch outcome {
        case .finished(let result):
            IdentifyAnnouncement.post(Self.spokenSummary(of: result))
        case .failed(let error):
            IdentifyAnnouncement.post(error.message)
        case .idle, .running, .needsChecklist:
            break
        }
    }

    /// "3 matches. Best: Walleye, 82%." VoiceOver reads the sign as "percent".
    private static func spokenSummary(of result: IdentificationResult) -> String {
        guard result.isFish else { return "That does not look like a fish." }
        guard let best = result.best else { return "No clear match." }
        let count = result.candidates.count
        let matches = count == 1 ? "1 match" : "\(count) matches"
        return "\(matches). Best: \(best.species.commonName), \(best.percentText)."
    }

    /// Nil when the run was cancelled.
    private static func identify(
        _ image: UIImage,
        engine: IdentifyEngine,
        apiKey: String,
        model: String,
        regions: Set<FishingRegion>
    ) async -> IdentifyPhase? {
        do {
            let result: IdentificationResult
            switch engine {
            case .claude:
                result = try await ClaudeIdentifier().identify(image: image, apiKey: apiKey, model: model, regions: regions)
            case .onDevice:
                result = try await OnDeviceIdentifier.identify(image: image)
            }
            return .finished(result)
        } catch is CancellationError {
            return nil
        } catch let error as IdentificationError {
            return .failed(error)
        } catch {
            return .failed(.failed(error.localizedDescription))
        }
    }
}

/// Full-width row with no card behind it, for big buttons and the photo.
private struct IdentifyClearRow: ViewModifier {
    func body(content: Content) -> some View {
        content
            .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
    }
}
