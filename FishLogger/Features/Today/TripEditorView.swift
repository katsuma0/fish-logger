import CoreLocation
import SwiftData
import SwiftUI
import UIKit

/// Everything about a trip in one form. Edits go straight to the model; values show in the user's units
/// and are stored in base units.
struct TripEditorView: View {
    @Bindable var trip: Trip

    @Environment(AppSettings.self) private var settings
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?

    @State private var isLocating = false
    @State private var locationMessage: String?
    @State private var isRefreshingWeather = false
    @State private var weatherMessage: String?
    @State private var isReadingBarometer = false
    @State private var barometerMessage: String?
    /// Where the trip started when the editor opened, so its catches can move by as much as it did.
    @State private var openedStart: Date

    private enum Field: Hashable {
        case name, airTemp, cloudCover, precipitation, windSpeed, pressure, waterTemp, notes
    }

    private static let compassPoints = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
    private static let decimalFormat = FloatingPointFormatStyle<Double>().precision(.fractionLength(0...2))

    init(trip: Trip) {
        _trip = Bindable(trip)
        _openedStart = State(initialValue: trip.startDate)
    }

    var body: some View {
        Form {
            spotSection
            timeSection
            weatherSection
            pressureSection
            waterSection
            skySection
            notesSection
        }
        // Standard 44 point rows at Small and Medium. Large and Extra large make every row taller
        // for wet or gloved hands, the same way the Settings pages do.
        .environment(\.defaultMinListRowHeight, settings.buttonSize.minTapSize)
        .navigationTitle("Trip")
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
        .onChange(of: trip.startDate) {
            updateSkyForStartDate()
        }
        .onDisappear {
            CatchLogger.save(modelContext)
        }
    }

    // MARK: Sections

    private var spotSection: some View {
        Section {
            TextField("Spot name", text: $trip.locationName)
                .textInputAutocapitalization(.words)
                .focused($focusedField, equals: .name)
            Picker("Water", selection: $trip.waterBody) {
                ForEach(WaterBodyType.allCases) { type in
                    Label(type.label, systemImage: type.symbolName).tag(type)
                }
            }
            Picker("Fishing from", selection: $trip.method) {
                ForEach(FishingMethod.allCases) { option in
                    Label(option.label, systemImage: option.symbolName).tag(option)
                }
            }
            LabeledContent("Coordinates", value: coordinateText)
            Button {
                Task { await useCurrentLocation() }
            } label: {
                HStack {
                    Label("Use current location", systemImage: "location.fill")
                    Spacer()
                    if isLocating {
                        ProgressView()
                    }
                }
            }
            .disabled(isLocating)
            if let locationMessage {
                Text(locationMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Spot")
        }
    }

    /// Catches never move on their own: a running trip whose start is corrected keeps its fish where
    /// they are. When the times leave some outside, one button brings them along.
    private var timeSection: some View {
        let outsideCount = catchesOutsideTimes.count
        return Section {
            DatePicker(
                "Started",
                selection: $trip.startDate,
                in: ...(trip.endDate ?? Date.now),
                displayedComponents: [.date, .hourAndMinute]
            )
            if trip.endDate != nil {
                DatePicker(
                    "Ended",
                    selection: endDateBinding,
                    in: trip.startDate...latestEndDate,
                    displayedComponents: [.date, .hourAndMinute]
                )
            } else {
                LabeledContent("Ended", value: "Still fishing")
            }
            if outsideCount > 0 {
                Button(moveCatchesTitle(outsideCount: outsideCount)) {
                    moveCatches()
                }
            }
        } header: {
            Text("Time")
        } footer: {
            if let footer = timeFooter(outsideCount: outsideCount) {
                Text(footer)
            }
        }
    }

    private var weatherSection: some View {
        Section {
            Picker("Weather", selection: $trip.weather) {
                Text("Not set").tag(WeatherCondition?.none)
                ForEach(WeatherCondition.allCases) { condition in
                    Label(condition.label, systemImage: condition.symbolName).tag(Optional(condition))
                }
            }
            numberRow(
                "Air",
                symbol: settings.temperatureUnit.symbol,
                value: unitBinding(\.airTempC, unit: settings.temperatureUnit),
                field: .airTemp,
                allowsNegative: true
            )
            numberRow("Cloud cover", symbol: "%", value: plainBinding(\.cloudCoverPct, range: 0...100), field: .cloudCover)
            numberRow("Rain", symbol: "mm", value: plainBinding(\.precipitationMm, range: 0...1000), field: .precipitation)
            numberRow(
                "Wind",
                symbol: settings.speedUnit.symbol,
                value: unitBinding(\.windSpeedKmh, unit: settings.speedUnit),
                field: .windSpeed
            )
            Picker("Wind from", selection: windPointBinding) {
                Text("Not set").tag(Int?.none)
                ForEach(0..<Self.compassPoints.count, id: \.self) { index in
                    Text(Self.compassPoints[index]).tag(Optional(index))
                }
            }
            Button {
                Task { await refreshWeather() }
            } label: {
                HStack {
                    Label("Get weather", systemImage: "cloud.sun")
                    Spacer()
                    if isRefreshingWeather {
                        ProgressView()
                    }
                }
            }
            .disabled(isRefreshingWeather)
            if let weatherMessage {
                Text(weatherMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Weather")
        } footer: {
            Text("Get weather replaces these with the weather report for the trip's start time and place.")
        }
    }

    private var pressureSection: some View {
        Section {
            numberRow(
                "Pressure",
                symbol: settings.pressureUnit.symbol,
                value: unitBinding(\.pressureHPa, unit: settings.pressureUnit),
                field: .pressure
            )
            Picker("Trend", selection: $trip.pressureTrend) {
                Text("Not set").tag(PressureTrend?.none)
                ForEach(PressureTrend.allCases) { trend in
                    Label(trend.label, systemImage: trend.symbolName).tag(Optional(trend))
                }
            }
            if BarometerService.shared.isAvailable {
                Button {
                    Task { await readBarometer() }
                } label: {
                    HStack {
                        Label("Read phone barometer", systemImage: "barometer")
                        Spacer()
                        if isReadingBarometer {
                            ProgressView()
                        }
                    }
                }
                .disabled(isReadingBarometer)
            }
            if let barometerMessage {
                Text(barometerMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Pressure")
        } footer: {
            Text("Sea-level pressure, the same number weather reports use.")
        }
    }

    private var waterSection: some View {
        Section {
            numberRow(
                "Water temperature",
                symbol: settings.temperatureUnit.symbol,
                value: unitBinding(\.waterTempC, unit: settings.temperatureUnit),
                field: .waterTemp
            )
            Picker("Clarity", selection: $trip.waterClarity) {
                Text("Not set").tag(WaterClarity?.none)
                ForEach(WaterClarity.allCases) { clarity in
                    Text(clarity.label).tag(Optional(clarity))
                }
            }
            Picker("Level", selection: $trip.waterLevel) {
                Text("Not set").tag(WaterLevel?.none)
                ForEach(WaterLevel.allCases) { level in
                    Text(level.label).tag(Optional(level))
                }
            }
        } header: {
            Text("Water")
        }
    }

    private var skySection: some View {
        let moon = Astronomy.moon(on: trip.startDate)
        let lit = Int((moon.illumination * 100).rounded())
        let moonText = "\(moon.name.label), \(lit)% lit"
        return Section {
            LabeledContent("Moon", value: moonText)
            LabeledContent("Sunrise", value: timeText(trip.sunrise))
            LabeledContent("Sunset", value: timeText(trip.sunset))
        } header: {
            Text("Sky")
        } footer: {
            if trip.coordinate == nil {
                Text("Sunrise and sunset need a location.")
            }
        }
    }

    private var notesSection: some View {
        Section {
            TextField("Lures, spots, anything worth remembering", text: $trip.notes, axis: .vertical)
                // One line to start, growing as the note does.
                .lineLimit(1...8)
                .focused($focusedField, equals: .notes)
        } header: {
            Text("Notes")
        }
    }

    // MARK: Rows and bindings

    private func numberRow(
        _ title: String,
        symbol: String,
        value: Binding<Double?>,
        field: Field,
        allowsNegative: Bool = false
    ) -> some View {
        LabeledContent(title) {
            HStack(spacing: 6) {
                TextField(title, value: value, format: Self.decimalFormat, prompt: Text("Not set"))
                    // The decimal pad has no minus key, and Ontario winters go below zero.
                    .keyboardType(allowsNegative ? UIKeyboardType.numbersAndPunctuation : UIKeyboardType.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .focused($focusedField, equals: field)
                Text(symbol)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func unitBinding<U: DisplayUnit>(_ keyPath: ReferenceWritableKeyPath<Trip, Double?>, unit: U) -> Binding<Double?> {
        let trip = trip
        return Binding<Double?>(
            get: { trip[keyPath: keyPath].map { unit.fromBase($0) } },
            set: { newValue in trip[keyPath: keyPath] = newValue.map { unit.toBase($0) } }
        )
    }

    private func plainBinding(_ keyPath: ReferenceWritableKeyPath<Trip, Double?>, range: ClosedRange<Double>) -> Binding<Double?> {
        let trip = trip
        return Binding<Double?>(
            get: { trip[keyPath: keyPath] },
            set: { newValue in
                trip[keyPath: keyPath] = newValue.map { min(range.upperBound, max(range.lowerBound, $0)) }
            }
        )
    }

    /// A trip cannot end in the future.
    private var latestEndDate: Date {
        max(trip.startDate, Date.now)
    }

    private var endDateBinding: Binding<Date> {
        let trip = trip
        return Binding<Date>(
            get: { trip.endDate ?? trip.startDate },
            set: { newValue in
                trip.endDate = min(max(newValue, trip.startDate), max(trip.startDate, Date.now))
            }
        )
    }

    /// From the start to the end, or to now while the trip runs.
    private var tripTimes: ClosedRange<Date> {
        trip.startDate...max(trip.startDate, trip.endDate ?? Date.now)
    }

    /// Skips catches deleted elsewhere while the editor is open, because reading one can crash.
    private var liveCatches: [FishCatch] {
        trip.catches.filter { !$0.isDeleted && $0.modelContext != nil }
    }

    private var catchesOutsideTimes: [FishCatch] {
        let times = tripTimes
        return liveCatches.filter { !times.contains($0.timestamp) }
    }

    /// A finished trip whose start moved, such as one logged late and moved back to the day it
    /// happened: every catch goes with it. A running trip, or one with only its end changed, is being
    /// trimmed, so only the catches left outside move.
    private var wholeTripMoved: Bool {
        trip.endDate != nil && trip.startDate != openedStart
    }

    private func moveCatchesTitle(outsideCount: Int) -> String {
        if wholeTripMoved {
            let count = liveCatches.count
            return count == 1 ? "Move the catch with the trip" : "Move the \(count) catches with the trip"
        }
        return outsideCount == 1 ? "Move the catch inside these times" : "Move the \(outsideCount) catches inside these times"
    }

    private func timeFooter(outsideCount: Int) -> String? {
        var lines: [String] = []
        if outsideCount == 1 {
            lines.append("1 catch is outside these times.")
        } else if outsideCount > 1 {
            lines.append("\(outsideCount) catches are outside these times.")
        }
        if trip.endDate == nil {
            lines.append("End the trip from the Today screen when you are done.")
        }
        return lines.isEmpty ? nil : lines.joined(separator: " ")
    }

    /// Eight compass points. Reported directions snap to the nearest one.
    private var windPointBinding: Binding<Int?> {
        let trip = trip
        return Binding<Int?>(
            get: {
                guard let degrees = trip.windDirectionDeg else { return nil }
                let normalized = (degrees.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360)
                return Int((normalized + 22.5) / 45) % 8
            },
            set: { newValue in
                trip.windDirectionDeg = newValue.map { Double($0) * 45 }
            }
        )
    }

    private var coordinateText: String {
        guard let latitude = trip.latitude, let longitude = trip.longitude else { return "Not set" }
        return String(format: "%.4f, %.4f", latitude, longitude)
    }

    private func timeText(_ date: Date?) -> String {
        guard let date else { return "Not known" }
        return date.formatted(date: .omitted, time: .shortened)
    }

    // MARK: Actions

    private func finish() {
        guard focusedField != nil else {
            CatchLogger.save(modelContext)
            dismiss()
            return
        }
        // Number fields commit when they lose focus, so give the last one a moment first.
        focusedField = nil
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 200_000_000)
            CatchLogger.save(modelContext)
            dismiss()
        }
    }

    /// A moved trip shifts every catch by as much as Started moved since the editor opened, so a trip
    /// moved to another day takes its fish along. Anything still outside goes to the nearest end, the
    /// same rule logging uses for a catch added to a finished trip.
    private func moveCatches() {
        let offset = wholeTripMoved ? trip.startDate.timeIntervalSince(openedStart) : 0
        let times = tripTimes
        for fishCatch in liveCatches {
            let moved = fishCatch.timestamp.addingTimeInterval(offset)
            fishCatch.timestamp = min(max(moved, times.lowerBound), times.upperBound)
        }
        openedStart = trip.startDate
        CatchLogger.save(modelContext)
    }

    private func updateSkyForStartDate() {
        trip.moonPhase = Astronomy.moon(on: trip.startDate).phase
        guard let latitude = trip.latitude, let longitude = trip.longitude else { return }
        let sun = Astronomy.sunTimes(on: trip.startDate, latitude: latitude, longitude: longitude)
        trip.sunrise = sun.sunrise
        trip.sunset = sun.sunset
    }

    private func useCurrentLocation() async {
        focusedField = nil
        isLocating = true
        locationMessage = nil
        let location = await LocationService.shared.currentLocation(maxAge: 60)
        isLocating = false
        // The trip may have been deleted elsewhere during the wait. Writing to it then would fail.
        guard !trip.isDeleted, trip.modelContext != nil else { return }
        guard let location else {
            locationMessage = LocationService.shared.isDenied
                ? "Location is off for this app. You can turn it on in the Settings app."
                : "No location fix yet. Try again in a moment."
            return
        }
        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude
        trip.latitude = latitude
        trip.longitude = longitude
        let sun = Astronomy.sunTimes(on: trip.startDate, latitude: latitude, longitude: longitude)
        trip.sunrise = sun.sunrise
        trip.sunset = sun.sunset
        if trip.locationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            if let saved = CatchLogger.nearbySpotName(to: location, in: modelContext) {
                trip.locationName = saved
            } else if let name = await LocationService.shared.placeName(for: location),
                      !trip.isDeleted, trip.modelContext != nil,
                      // The person may have typed a name while the geocoder was working.
                      trip.locationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                trip.locationName = name
            }
        }
        CatchLogger.save(modelContext)
    }

    private func refreshWeather() async {
        focusedField = nil
        isRefreshingWeather = true
        weatherMessage = nil
        let before = trip.weatherFetchedAt
        await TripConditionsUpdater.refresh(trip, in: modelContext, forceWeather: true)
        isRefreshingWeather = false
        if trip.weatherFetchedAt == before {
            weatherMessage = trip.coordinate == nil
                ? "This trip has no location, so there is no weather to look up."
                : "No signal or no data. Try again later."
        }
    }

    private func readBarometer() async {
        focusedField = nil
        isReadingBarometer = true
        barometerMessage = nil
        let station = await BarometerService.shared.readOnce()
        isReadingBarometer = false
        guard let station else {
            barometerMessage = "No reading from the barometer. Try again."
            return
        }
        let altitude = LocationService.shared.recentLocation()?.altitude ?? 0
        trip.pressureHPa = BarometerService.seaLevel(
            stationHPa: station,
            altitudeM: altitude,
            airTempC: trip.airTempC ?? 15
        )
        CatchLogger.save(modelContext)
    }
}
