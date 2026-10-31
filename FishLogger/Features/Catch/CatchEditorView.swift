import SwiftData
import SwiftUI
import UIKit

/// Everything about one catch. Edits write straight to the model, which autosaves; Done saves as well.
/// Has no NavigationStack of its own: push it, or wrap it in one inside a sheet.
struct CatchEditorView: View {
    @Bindable var fishCatch: FishCatch

    @Environment(AppSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    @State private var sizeMode: SizeEntryMode?
    /// Up to eight distinct lures from other catches, newest first. Fetched once when the editor
    /// opens rather than kept live, so typing in the Lure field never walks past catches.
    @State private var recentLures: [String] = []
    @State private var didLoadRecentLures = false
    @State private var showingDeleteConfirmation = false
    @State private var didDelete = false
    /// The catch's time and its trip's start and end when the editor opened. See `keepTripAroundCatch`.
    @State private var opening: CatchEditorOpening?
    @FocusState private var focusedField: CatchEditorField?

    init(fishCatch: FishCatch) {
        _fishCatch = Bindable(wrappedValue: fishCatch)
    }

    var body: some View {
        Group {
            if isGone {
                // On the way out after a delete. Nothing in here may read the model.
                Color.clear
            } else {
                editor
            }
        }
        .onChange(of: isGone) { _, gone in
            // Deleted somewhere else while open, for example from a list next to this one on iPad.
            if gone, !didDelete { dismiss() }
        }
    }

    private var isGone: Bool { didDelete || fishCatch.catchEditorIsGone }

    private var editor: some View {
        Form {
            speciesSection
            // Right under the species, so Take photo is on screen when the editor opens.
            CatchEditorPhotosSection(fishCatch: fishCatch)
            whenSection
            sizeSection
            releasedSection
            lureSection
            CatchEditorLocationSection(fishCatch: fishCatch)
            notesSection
            deleteSection
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(fishCatch.speciesName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { finish() }
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focusedField = nil }
            }
        }
        .onAppear {
            chooseInitialSizeMode()
            rememberOpening()
        }
        // Covers a swipe down as well as Done. Also runs when the species list is pushed over the
        // editor, which is harmless because the trip is always worked out again from `opening`.
        .onDisappear {
            if keepTripAroundCatch(), let context = fishCatch.catchEditorLiveContext {
                CatchLogger.save(context)
            }
        }
        .task { loadRecentLures() }
    }

    // MARK: Species

    private var isUnknownSpecies: Bool {
        fishCatch.speciesID == SpeciesCatalog.unknownID || fishCatch.species == nil
    }

    /// The placeholder "Unknown fish" has made-up size cutoffs, so it never drives ranges or estimates.
    private var knownSpecies: Species? {
        isUnknownSpecies ? nil : fishCatch.species
    }

    private var speciesSection: some View {
        Section {
            // Pushed inside the editor's own navigation stack, so Back returns here with nothing lost.
            NavigationLink {
                SpeciesPickerView(title: "Change species", allowsUnknown: true, showsCancel: false, onPick: { species in
                    pickSpecies(species)
                })
            } label: {
                HStack(spacing: 12) {
                    SpeciesIcon(species: fishCatch.species, size: settings.buttonSize.iconSize + 10)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(fishCatch.speciesName)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        if let scientific = knownSpecies?.scientificName, !scientific.isEmpty {
                            Text(scientific)
                                .font(.caption)
                                .italic()
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer(minLength: 8)
                }
                .frame(minHeight: settings.buttonSize.minTapSize)
                .contentShape(Rectangle())
            }
            .accessibilityLabel("Species, \(fishCatch.speciesName)")
            .accessibilityHint("Opens the species list to change it")

            if isUnknownSpecies {
                TextField("Name it yourself", text: customNameBinding)
                    .textInputAutocapitalization(.words)
                    .submitLabel(.done)
                    .focused($focusedField, equals: .customName)
                    .frame(minHeight: settings.buttonSize.minTapSize)
            }
        } header: {
            Text("Species")
        } footer: {
            if let source = fishCatch.identifiedBy {
                Text(identificationNote(source))
            }
        }
    }

    private var customNameBinding: Binding<String> {
        let model = fishCatch
        return Binding(
            get: { model.customSpeciesName ?? "" },
            set: { model.customSpeciesName = $0.isEmpty ? nil : $0 }
        )
    }

    private func identificationNote(_ source: IdentificationSource) -> String {
        switch source {
        case .manual: "Species picked by hand."
        case .claude: "Species from Photo ID."
        case .onDevice: "Species from the on-device model."
        case .traitKey: "Species from the feature checklist."
        }
    }

    // MARK: When and how many

    private var whenSection: some View {
        Section("When and how many") {
            // No future times. A time outside the trip is allowed and widens the trip when the editor
            // closes, so a fish forgotten after the trip ended can still be added.
            DatePicker("Caught", selection: $fishCatch.timestamp, in: ...Date.now, displayedComponents: [.date, .hourAndMinute])
                .frame(minHeight: settings.buttonSize.minTapSize)
            Stepper(value: $fishCatch.count, in: 1...99) {
                Text("Count: \(fishCatch.count)")
            }
            .frame(minHeight: settings.buttonSize.minTapSize)
        }
    }

    // MARK: Size

    private var activeSizeMode: SizeEntryMode { sizeMode ?? settings.sizeEntryMode }

    private var sizeModeBinding: Binding<SizeEntryMode> {
        Binding(
            get: { sizeMode ?? settings.sizeEntryMode },
            set: { sizeMode = $0 }
        )
    }

    private var sizeSection: some View {
        Section {
            Picker("Size entry", selection: sizeModeBinding) {
                ForEach(SizeEntryMode.allCases) { mode in
                    Text(mode.label).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .controlSize(segmentedControlSize)

            switch activeSizeMode {
            case .category:
                SizeClassPicker(selection: $fishCatch.sizeClass, species: knownSpecies)
                    .padding(.vertical, 4)
            case .exact:
                measurementField("Length", symbol: settings.lengthUnit.symbol, value: lengthBinding, field: .length)
                measurementField("Weight", symbol: settings.weightUnit.symbol, value: weightBinding, field: .weight)
            }
        } header: {
            Text("Size")
        } footer: {
            if !sizeNotes.isEmpty {
                Text(sizeNotes.joined(separator: "\n"))
            }
        }
    }

    /// Derived hints under the size inputs. Both modes edit the same catch, so each mode mentions what the other holds.
    private var sizeNotes: [String] {
        var notes: [String] = []
        let species = knownSpecies
        switch activeSizeMode {
        case .exact:
            if let length = fishCatch.lengthCm, let species {
                let fromLength = species.sizeClass(forLengthCm: length)
                if let picked = fishCatch.sizeClass, picked != fromLength {
                    notes.append("Marked \(picked.label.lowercased()). The length says \(fromLength.label.lowercased()).")
                } else {
                    notes.append("Size class: \(fromLength.label).")
                }
                if fishCatch.weightKg == nil, let estimate = species.estimatedWeightKg(lengthCm: length) {
                    notes.append("About \(settings.weight(estimate)) by the length-weight curve.")
                }
            } else if let picked = fishCatch.sizeClass {
                notes.append("Size class: \(picked.label).")
            }
        case .category:
            var measured: [String] = []
            if let length = fishCatch.lengthCm { measured.append(settings.length(length)) }
            if let weight = fishCatch.weightKg { measured.append(settings.weight(weight)) }
            if !measured.isEmpty {
                notes.append("Measured: \(measured.joined(separator: ", ")).")
            } else if let picked = fishCatch.sizeClass, let species,
                      let estimate = species.estimatedWeightKg(lengthCm: species.representativeLengthCm(for: picked)) {
                notes.append("A typical \(picked.label.lowercased()) one is about \(settings.weight(estimate)).")
            }
        }
        return notes
    }

    private var segmentedControlSize: ControlSize {
        switch settings.buttonSize {
        case .small, .medium: .regular
        case .large, .extraLarge: .large
        }
    }

    private func measurementField(
        _ title: String,
        symbol: String,
        value: Binding<Double?>,
        field: CatchEditorField
    ) -> some View {
        LabeledContent(title) {
            HStack(spacing: 6) {
                TextField(title, value: value, format: .number.precision(.fractionLength(0...2)), prompt: Text("Add"))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .focused($focusedField, equals: field)
                Text(symbol)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(minHeight: settings.buttonSize.minTapSize)
    }

    private var lengthBinding: Binding<Double?> {
        let unit = settings.lengthUnit
        return convertedBinding(\.lengthCm, fromBase: { unit.fromBase($0) }, toBase: { unit.toBase($0) })
    }

    private var weightBinding: Binding<Double?> {
        let unit = settings.weightUnit
        return convertedBinding(\.weightKg, fromBase: { unit.fromBase($0) }, toBase: { unit.toBase($0) })
    }

    private var depthBinding: Binding<Double?> {
        let unit = settings.depthUnit
        return convertedBinding(\.depthM, fromBase: { unit.fromBase($0) }, toBase: { unit.toBase($0) })
    }

    private var waterTempBinding: Binding<Double?> {
        let unit = settings.temperatureUnit
        return convertedBinding(\.waterTempC, fromBase: { unit.fromBase($0) }, toBase: { unit.toBase($0) })
    }

    /// Shows a base-unit value in display units and stores typed values back in base units.
    private func convertedBinding(
        _ keyPath: ReferenceWritableKeyPath<FishCatch, Double?>,
        fromBase: @escaping (Double) -> Double,
        toBase: @escaping (Double) -> Double
    ) -> Binding<Double?> {
        let model = fishCatch
        return Binding(
            get: {
                model[keyPath: keyPath].map { catchEditorRounded(fromBase($0)) }
            },
            set: { newValue in
                let shown = model[keyPath: keyPath].map { catchEditorRounded(fromBase($0)) }
                // The field writes back on every commit. Skipping unchanged values keeps a stored
                // 45.5 cm from drifting through a round trip in inches.
                guard newValue != shown else { return }
                model[keyPath: keyPath] = newValue.map { toBase($0) }
            }
        )
    }

    // MARK: Released, lure, water

    private var releasedSection: some View {
        Section("Released or kept") {
            Picker("Released or kept", selection: $fishCatch.released) {
                Text("Released").tag(true)
                Text("Kept").tag(false)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .controlSize(segmentedControlSize)
        }
    }

    private var lureSection: some View {
        Section("Lure and water") {
            TextField("Lure or bait", text: $fishCatch.lure)
                .textInputAutocapitalization(.sentences)
                .submitLabel(.done)
                .focused($focusedField, equals: .lure)
                .frame(minHeight: settings.buttonSize.minTapSize)

            if !recentLures.isEmpty {
                // Trimmed once here, not once per chip.
                let current = fishCatch.lure.trimmingCharacters(in: .whitespacesAndNewlines)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Recent")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .accessibilityAddTraits(.isHeader)
                    FlowLayout(spacing: 8, lineSpacing: 8) {
                        ForEach(recentLures, id: \.self) { lure in
                            lureChip(lure, isCurrent: current.caseInsensitiveCompare(lure) == .orderedSame)
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            measurementField("Depth", symbol: settings.depthUnit.symbol, value: depthBinding, field: .depth)
            measurementField("Water temp", symbol: settings.temperatureUnit.symbol, value: waterTempBinding, field: .waterTemp)
        }
    }

    /// No haptic: picking a chip is a plain selection, and the field changing is feedback enough.
    private func lureChip(_ lure: String, isCurrent: Bool) -> some View {
        // A capsule at one line. A long lure wraps instead of truncating, and keeps its text inside.
        let chipShape = RoundedRectangle(cornerRadius: settings.buttonSize.minTapSize / 2, style: .continuous)
        return Button {
            fishCatch.lure = lure
        } label: {
            Text(lure)
                .font(.subheadline)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .frame(minHeight: settings.buttonSize.minTapSize)
                .foregroundStyle(isCurrent ? Color.white : Color.primary)
                .background(
                    chipShape.fill(isCurrent ? Theme.accentFill : Color(uiColor: .tertiarySystemFill))
                )
                .overlay(
                    chipShape.strokeBorder(
                        settings.usesStrongContrast(colorSchemeContrast) ? Color.primary : Color.clear,
                        lineWidth: 1.5
                    )
                )
                .contentShape(chipShape)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Use \(lure)")
        .accessibilityAddTraits(isCurrent ? .isSelected : [])
    }

    // MARK: Notes and delete

    private var notesSection: some View {
        Section("Notes") {
            TextField("Notes", text: $fishCatch.notes, axis: .vertical)
                .lineLimit(3...10)
                .focused($focusedField, equals: .notes)
        }
    }

    private var deleteSection: some View {
        Section {
            Button(role: .destructive) {
                focusedField = nil
                showingDeleteConfirmation = true
            } label: {
                Label("Delete catch", systemImage: "trash")
                    .frame(maxWidth: .infinity, minHeight: settings.buttonSize.minTapSize)
                    .contentShape(Rectangle())
            }
            .confirmationDialog(
                "Delete this catch?",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete catch", role: .destructive) { deleteCatch() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Its photos go with it. This cannot be undone.")
            }
        }
    }

    // MARK: Actions

    private func chooseInitialSizeMode() {
        guard sizeMode == nil, !isGone else { return }
        // A measured fish with no size class opens on the numbers, so they are not hidden.
        if fishCatch.hasMeasurement && fishCatch.sizeClass == nil {
            sizeMode = .exact
        } else {
            sizeMode = settings.sizeEntryMode
        }
    }

    /// Fetches only the lure column of the latest 60 catches that have one, then keeps eight
    /// distinct ones. Runs once per editor, not on every keystroke.
    private func loadRecentLures() {
        guard !didLoadRecentLures, let context = fishCatch.catchEditorLiveContext else { return }
        didLoadRecentLures = true
        let currentID = fishCatch.id
        var descriptor = FetchDescriptor<FishCatch>(
            predicate: #Predicate<FishCatch> { $0.lure != "" && $0.id != currentID },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        descriptor.fetchLimit = 60
        descriptor.propertiesToFetch = [\.lure]
        let catches = (try? context.fetch(descriptor)) ?? []
        var seen = Set<String>()
        var lures: [String] = []
        for other in catches where !other.isDeleted {
            let lure = other.lure.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !lure.isEmpty, seen.insert(lure.lowercased()).inserted else { continue }
            lures.append(lure)
            if lures.count == 8 { break }
        }
        recentLures = lures
    }

    private func pickSpecies(_ species: Species) {
        focusedField = nil
        guard let context = fishCatch.catchEditorLiveContext else { return }
        let changed = species.id != fishCatch.speciesID
        if changed {
            fishCatch.speciesID = species.id
            // A hand correction means the photo ID was overruled, which stats want to know.
            fishCatch.identifiedBy = .manual
        }
        // Keep a typed name only when "Unknown fish" is picked again.
        if changed || species.id != SpeciesCatalog.unknownID {
            fishCatch.customSpeciesName = nil
        }
        CatchLogger.save(context)
    }

    private func rememberOpening() {
        guard opening == nil, !isGone else { return }
        let trip = fishCatch.trip
        opening = CatchEditorOpening(
            timestamp: fishCatch.timestamp,
            tripStart: trip?.startDate,
            tripEnd: trip?.endDate
        )
    }

    /// A catch moved before its trip's start or past its end widens the trip, so the catch stays
    /// inside the trip it is listed under and Stats count that time as fishing. Worked out from the
    /// trip as it was when the editor opened, so a time picked by mistake and then fixed leaves the
    /// trip as it was. Runs on close rather than on every change, because the picker writes while it
    /// spins. Returns true when it changed the trip.
    @discardableResult
    private func keepTripAroundCatch() -> Bool {
        guard !isGone, let opening, let trip = fishCatch.trip, !trip.isDeleted, trip.modelContext != nil else {
            return false
        }
        let time = fishCatch.timestamp
        // Only a time changed here moves the trip, so opening an old catch and tapping Done never does.
        let moved = time != opening.timestamp
        let baseStart = opening.tripStart ?? trip.startDate
        let wantedStart = moved ? min(baseStart, time) : baseStart
        var changed = false
        if trip.startDate != wantedStart {
            trip.startDate = wantedStart
            changed = true
        }
        // A running trip has no end to move.
        if let end = trip.endDate {
            let baseEnd = opening.tripEnd ?? end
            let wantedEnd = moved ? max(baseEnd, time) : baseEnd
            if end != wantedEnd {
                trip.endDate = wantedEnd
                changed = true
            }
        }
        return changed
    }

    private func finish() {
        focusedField = nil
        keepTripAroundCatch()
        if let context = fishCatch.catchEditorLiveContext {
            CatchLogger.save(context)
        }
        dismiss()
    }

    private func deleteCatch() {
        guard !didDelete, let context = fishCatch.catchEditorLiveContext else {
            dismiss()
            return
        }
        // Flip the flag first so the next render shows nothing that reads the deleted model.
        didDelete = true
        focusedField = nil
        CatchLogger.delete(fishCatch, in: context)
        Haptics.warning()
        dismiss()
    }
}

/// What the editor saw when it opened, so closing it can tell whether the catch's time moved.
private struct CatchEditorOpening {
    let timestamp: Date
    /// Nil when the catch has no trip.
    let tripStart: Date?
    let tripEnd: Date?
}

/// Two decimals is finer than anyone measures a fish, and keeps 17.913385 in from showing up in a field.
private func catchEditorRounded(_ value: Double) -> Double {
    (value * 100).rounded() / 100
}

#Preview {
    let container = AppModelContainer.inMemory()
    let fishCatch = CatchLogger.logCatch(speciesID: "walleye", sizeClass: .large, in: container.mainContext)
    NavigationStack {
        CatchEditorView(fishCatch: fishCatch)
    }
    .modelContainer(container)
    .environment(AppSettings.shared)
}
