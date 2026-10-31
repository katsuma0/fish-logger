import CoreLocation
import SwiftData
import SwiftUI

/// Start a trip in two taps: Start fishing on Today, then Start fishing here. Everything is prefilled.
struct TodayStartTripSheet: View {
    let onStart: (Trip) -> Void

    @Environment(AppSettings.self) private var settings
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    @State private var locationName = ""
    @State private var nameTouched = false
    @State private var waterBody: WaterBodyType
    @State private var method: FishingMethod
    @State private var spotNames: [String] = []
    @State private var isLocating = false
    @State private var didLoad = false
    @State private var didStart = false
    @FocusState private var nameFocused: Bool

    private static let maxSpots = 8

    init(lastTrip: Trip?, onStart: @escaping (Trip) -> Void) {
        self.onStart = onStart
        _waterBody = State(initialValue: lastTrip?.waterBody ?? .lake)
        _method = State(initialValue: lastTrip?.method ?? .shore)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 8) {
                        TextField("Spot name", text: nameBinding)
                            .textInputAutocapitalization(.words)
                            .submitLabel(.done)
                            .focused($nameFocused)
                        if isLocating {
                            ProgressView()
                                .accessibilityLabel("Finding your spot")
                        }
                    }
                    .frame(minHeight: settings.buttonSize.minTapSize)
                } header: {
                    Text("Where")
                } footer: {
                    Text("Leave it empty and the app names it from your location.")
                }

                if !spotNames.isEmpty {
                    Section("Saved spots") {
                        FlowLayout(spacing: 8, lineSpacing: 8) {
                            ForEach(spotNames, id: \.self) { name in
                                spotChip(name)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("How") {
                    Picker("Water", selection: $waterBody) {
                        ForEach(WaterBodyType.allCases) { type in
                            Label(type.label, systemImage: type.symbolName).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(minHeight: settings.buttonSize.minTapSize)
                    Picker("Fishing from", selection: $method) {
                        ForEach(FishingMethod.allCases) { option in
                            Label(option.label, systemImage: option.symbolName).tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(minHeight: settings.buttonSize.minTapSize)
                }

                Section {
                    Toggle("Keep screen on", isOn: keepScreenOnBinding)
                        .frame(minHeight: settings.buttonSize.minTapSize)
                } footer: {
                    Text("Stops the screen from locking while a trip is running. Uses more battery.")
                }
            }
            .navigationTitle("Start a trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            // The only Start button, at the bottom where the thumb is.
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Button {
                    start()
                } label: {
                    Label("Start fishing", systemImage: "figure.fishing")
                }
                .buttonStyle(PrimaryActionButtonStyle())
                .disabled(didStart)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.bar)
            }
            .task {
                await load()
            }
        }
        .presentationDetents([.medium, .large])
    }

    /// Marks the name as typed by hand, so a slow GPS answer never overwrites it.
    private var nameBinding: Binding<String> {
        Binding<String>(
            get: { locationName },
            set: { newValue in
                locationName = newValue
                nameTouched = true
            }
        )
    }

    /// Same setting as in Settings, here because the start of a trip is when it matters.
    private var keepScreenOnBinding: Binding<Bool> {
        let settings = settings
        return Binding<Bool>(
            get: { settings.keepScreenOn },
            set: { newValue in settings.keepScreenOn = newValue }
        )
    }

    private func spotChip(_ name: String) -> some View {
        let current = locationName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let isSelected = current == name.lowercased()
        let strong = settings.usesStrongContrast(colorSchemeContrast)
        return Button {
            nameTouched = true
            locationName = name
            nameFocused = false
        } label: {
            Text(name)
                .font(.subheadline)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(minHeight: settings.buttonSize.minTapSize)
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .background(
                    Capsule().fill(isSelected ? Theme.accentFill : Color(uiColor: .tertiarySystemFill))
                )
                .overlay(
                    Capsule().strokeBorder(strong ? Color.primary : Color.clear, lineWidth: 1.5)
                )
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    /// One fetch of saved spots feeds both the chips and the nearby match.
    private func load() async {
        guard !didLoad else { return }
        didLoad = true
        let spots = CatchLogger.savedSpots(in: modelContext)
        spotNames = spots.prefix(Self.maxSpots).map { $0.name }

        isLocating = true
        let location = await LocationService.shared.currentLocation()
        var suggestion: String?
        if let location {
            suggestion = CatchLogger.nearbySpotName(to: location, among: spots)
            if suggestion == nil {
                suggestion = await LocationService.shared.placeName(for: location)
            }
        }
        isLocating = false

        guard let suggestion, !nameTouched else { return }
        guard locationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        locationName = suggestion
    }

    private func start() {
        guard !didStart else { return }
        didStart = true
        let name = locationName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trip = CatchLogger.startTrip(in: modelContext, locationName: name, waterBody: waterBody, method: method)
        Haptics.logged()
        onStart(trip)
        dismiss()
        let context = modelContext
        Task {
            await TripConditionsUpdater.refresh(trip, in: context)
        }
    }
}
