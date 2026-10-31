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

    private enum Field: Hashable {
        case name, airTemp, cloudCover, precipitation, windSpeed, pressure, waterTemp, notes
    }

    private static let compassPoints = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
    private static let decimalFormat = FloatingPointFormatStyle<Double>().precision(.fractionLength(0...2))

    init(trip: Trip) {
        _trip = Bindable(trip)
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
                .tripEditorRow(settings)
            Picker("Water", selection: $trip.waterBody) {
                ForEach(WaterBodyType.allCases) { type in
                    Label(type.label, systemImage: type.symbolName).tag(type)
                }
            }
            .tripEditorRow(settings)
            Picker("Fishing from", selection: $trip.method) {
                ForEach(FishingMethod.allCases) { option in
                    Label(option.label, systemImage: option.symbolName).tag(option)
                }
            }
            .tripEditorRow(settings)
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
                .tripEditorRow(settings)
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

    private var timeSection: some View {
        Section {
            DatePicker(
                "Started",
                selection: $trip.startDate,
                in: ...(trip.endDate ?? Date.now),
                displayedComponents: [.date, .hourAndMinute]
            )
            .tripEditorRow(settings)
            if trip.endDate != nil {
                DatePicker(
                    "Ended",
                    selection: endDateBinding,
                    in: trip.startDate...,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .tripEditorRow(settings)
            } else {
                LabeledContent("Ended", value: "Still fishing")
            }
        } header: {
            Text("Time")
        } footer: {
            if trip.endDate == nil {
                Text("End the trip from the Today screen when you are done.")
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
            .tripEditorRow(settings)
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
            .tripEditorRow(settings)
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
                .tripEditorRow(settings)
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
            .tripEditorRow(settings)
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
                    .tripEditorRow(settings)
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
            .tripEditorRow(settings)
            Picker("Level", selection: $trip.waterLevel) {
                Text("Not set").tag(WaterLevel?.none)
                ForEach(WaterLevel.allCases) { level in
                    Text(level.label).tag(Optional(level))
                }
            }
            .tripEditorRow(settings)
        } header: {
            Text("Water")
        }
    }

    private var skySection: some View {
        let moon = Astronomy.moon(on: trip.startDate)
        let lit = Int((moon.illumination * 100).rounded())
        let moonText = "\(moon.name.label), \(lit)% lit"
        return Section {
            LabeledContent("Moon") {
                Label(moonText, systemImage: moon.name.symbolName)
            }
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
                .lineLimit(3...8)
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
        .tripEditorRow(settings)
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

    private var endDateBinding: Binding<Date> {
        let trip = trip
        return Binding<Date>(
            get: { trip.endDate ?? trip.startDate },
            set: { newValue in trip.endDate = max(newValue, trip.startDate) }
        )
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
            } else if let name = await LocationService.shared.placeName(for: location) {
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

private extension View {
    /// Form rows follow the Button size setting, so wet or gloved hands hit them as easily as the
    /// catch editor's rows.
    func tripEditorRow(_ settings: AppSettings) -> some View {
        frame(minHeight: settings.buttonSize.minTapSize)
    }
}
