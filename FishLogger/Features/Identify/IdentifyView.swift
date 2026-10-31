import PhotosUI
import SwiftData
import SwiftUI
import UIKit

/// Screens IdentifyView can push.
private enum IdentifyRoute: Hashable {
    case checklist
    case confirm(speciesID: String, source: IdentificationSource)
}

/// Where photo ID stands for the current photo.
private enum IdentifyPhase {
    case idle
    case running(String)
    case finished(IdentificationResult)
    case failed(IdentificationError)
    /// No engine can look at photos on this phone, so the checklist is the way.
    case needsChecklist
}

/// Photo to species to logged catch. Presented in a sheet; owns its NavigationStack.
/// Photos only leave the phone when a key is saved and photo ID is on, and only after one is chosen.
struct IdentifyView: View {
    let initialImage: UIImage?
    let onLogged: ((FishCatch) -> Void)?

    @Environment(AppSettings.self) private var settings
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var image: UIImage?
    @State private var phase: IdentifyPhase = .idle
    @State private var path: [IdentifyRoute] = []
    /// Bumped for each new photo or retry; the identification task follows it.
    @State private var runToken = 0
    /// The token that already has an answer, so reappearing after the camera does not resend the photo.
    @State private var answeredToken: Int? = nil
    @State private var preferOnDevice = false
    @State private var hasAPIKey = false
    @State private var keyChecked = false
    @State private var showingCamera = false
    @State private var photoItem: PhotosPickerItem? = nil
    @State private var isLoadingPhoto = false
    @State private var photoLoadFailed = false
    @State private var showingSpeciesPicker = false
    @State private var pendingManualPickID: String? = nil

    init(initialImage: UIImage? = nil, onLogged: ((FishCatch) -> Void)? = nil) {
        self.initialImage = initialImage
        self.onLogged = onLogged
        _image = State(initialValue: initialImage)
    }

    var body: some View {
        NavigationStack(path: $path) {
            rootList
                .navigationTitle("Identify")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                }
                .navigationDestination(for: IdentifyRoute.self) { route in
                    destination(for: route)
                }
        }
        .onAppear {
            hasAPIKey = KeychainStore.hasValue(for: .anthropicAPIKey)
            keyChecked = true
        }
        .task(id: runToken) {
            await runIdentification()
        }
        .onChange(of: photoItem) { _, newItem in
            guard let newItem else { return }
            loadPhoto(from: newItem)
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
                if showsSetupNoteSection, let note = setupNote {
                    Section {
                        Label(note, systemImage: "key")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
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
        }

        Section {
            Button {
                path.append(.checklist)
            } label: {
                Label("Use the checklist instead", systemImage: "checklist")
                    .frame(minHeight: settings.buttonSize.minTapSize)
            }
        } footer: {
            if keyChecked, let note = setupNote {
                Text(note)
            }
        }
    }

    private func photoSection(_ image: UIImage) -> some View {
        Section {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
                .frame(maxWidth: .infinity, maxHeight: 280)
                .accessibilityLabel("Your photo")
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
            EmptyView()

        case .running(let message):
            Section {
                loadingRow(message)
            }

        case .failed(let error):
            Section {
                Label(error.message, systemImage: "exclamationmark.triangle.fill")
                    .fixedSize(horizontal: false, vertical: true)
                actionRow("Try again", systemImage: "arrow.clockwise") {
                    retry(onDevice: preferOnDevice)
                }
                if !preferOnDevice, OnDeviceIdentifier.isAvailable {
                    actionRow("Use the on-device model", systemImage: "iphone") {
                        retry(onDevice: true)
                    }
                }
                checklistRow
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
            }
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
                photo: image,
                source: source,
                onLog: { sizeClass, count in
                    log(speciesID: speciesID, source: source, sizeClass: sizeClass, count: count)
                }
            )
        }
    }

    // MARK: Setup

    private var claudeReady: Bool { settings.photoIDEnabled && hasAPIKey }

    private var setupNote: String? {
        if !hasAPIKey { return IdentificationError.notConfigured.message }
        if !settings.photoIDEnabled { return IdentificationError.photoIDDisabled.message }
        return nil
    }

    /// The needs-checklist section already says it, so the separate note would repeat it.
    private var showsSetupNoteSection: Bool {
        guard keyChecked, !claudeReady else { return false }
        if case .needsChecklist = phase { return false }
        return true
    }

    // MARK: Actions

    private func useImage(_ newImage: UIImage) {
        image = newImage
        photoLoadFailed = false
        phase = .idle
        preferOnDevice = false
        path.removeAll()
        runToken += 1
    }

    private func retry(onDevice: Bool) {
        preferOnDevice = onDevice
        phase = .idle
        runToken += 1
    }

    private func loadPhoto(from item: PhotosPickerItem) {
        isLoadingPhoto = true
        photoLoadFailed = false
        Task {
            let data = try? await item.loadTransferable(type: Data.self)
            isLoadingPhoto = false
            // Cleared so picking the same photo again still counts as a change.
            photoItem = nil
            if let data, let picked = UIImage(data: data) {
                useImage(picked)
            } else {
                photoLoadFailed = true
                Haptics.warning()
            }
        }
    }

    private func openPendingManualPick() {
        guard let speciesID = pendingManualPickID else { return }
        pendingManualPickID = nil
        path.append(.confirm(speciesID: speciesID, source: .manual))
    }

    private func log(speciesID: String, source: IdentificationSource, sizeClass: SizeClass?, count: Int) {
        let fishCatch = CatchLogger.logCatch(
            speciesID: speciesID,
            count: count,
            sizeClass: sizeClass,
            photo: image,
            identifiedBy: source,
            in: modelContext
        )
        Haptics.logged()
        onLogged?(fishCatch)
        dismiss()
    }

    // MARK: Identification

    private func runIdentification() async {
        guard let image, answeredToken != runToken else { return }
        let token = runToken
        let apiKey = KeychainStore.string(for: .anthropicAPIKey)
        hasAPIKey = apiKey != nil
        keyChecked = true

        let outcome: IdentifyPhase?
        if !preferOnDevice, settings.photoIDEnabled, let apiKey {
            let model = settings.claudeModel
            phase = .running("Looking at the fish")
            outcome = await attempt {
                try await ClaudeIdentifier().identify(image: image, apiKey: apiKey, model: model)
            }
        } else if OnDeviceIdentifier.isAvailable {
            phase = .running("Checking the photo on this phone")
            outcome = await attempt {
                try await OnDeviceIdentifier.identify(image: image)
            }
        } else {
            outcome = .needsChecklist
        }

        // A cancelled run leaves no answer, so it runs again when the screen comes back.
        guard let finalPhase = outcome, !Task.isCancelled, token == runToken else { return }
        phase = finalPhase
        answeredToken = token
        if case .failed = finalPhase { Haptics.warning() }
    }

    private func attempt(_ work: () async throws -> IdentificationResult) async -> IdentifyPhase? {
        do {
            let result = try await work()
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
