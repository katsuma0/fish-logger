import SwiftUI

/// How the catch editor starts, location tags on each fish, and keeping the screen awake.
struct SettingsLoggingView: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings
        List {
            Section {
                Picker("Size entry", selection: $settings.sizeEntryMode) {
                    ForEach(SizeEntryMode.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                .pickerStyle(.menu)
            } footer: {
                Text("Which size input the catch editor shows first. Size class is a quick pick from dink to trophy. Measure takes the length and weight.")
            }

            Section {
                Toggle("Tag catches with location", isOn: $settings.tagCatchLocation)
            } footer: {
                Text("Saves the spot for each fish, not only for the trip. Needs location access.")
            }

            Section {
                Toggle("Keep screen on during trips", isOn: $settings.keepScreenOn)
            } footer: {
                Text("No Face ID or passcode for every fish. Uses more battery.")
            }
        }
        .settingsListStyle()
        .navigationTitle("Logging")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Display units for length, weight, temperature, pressure, wind, and depth.
struct SettingsUnitsView: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings
        List {
            Section {
                Picker("Length", selection: $settings.lengthUnit) {
                    ForEach(LengthUnit.allCases, id: \.self) { unit in
                        Text(Self.unitTitle(unit.label, unit.symbol)).tag(unit)
                    }
                }
                Picker("Weight", selection: $settings.weightUnit) {
                    ForEach(WeightUnit.allCases, id: \.self) { unit in
                        Text(Self.unitTitle(unit.label, unit.symbol)).tag(unit)
                    }
                }
                Picker("Temperature", selection: $settings.temperatureUnit) {
                    ForEach(TemperatureUnit.allCases, id: \.self) { unit in
                        Text(Self.unitTitle(unit.label, unit.symbol)).tag(unit)
                    }
                }
                Picker("Pressure", selection: $settings.pressureUnit) {
                    ForEach(PressureUnit.allCases, id: \.self) { unit in
                        Text(Self.unitTitle(unit.label, unit.symbol)).tag(unit)
                    }
                }
                Picker("Wind speed", selection: $settings.speedUnit) {
                    ForEach(SpeedUnit.allCases, id: \.self) { unit in
                        Text(Self.unitTitle(unit.label, unit.symbol)).tag(unit)
                    }
                }
                Picker("Depth", selection: $settings.depthUnit) {
                    ForEach(DepthUnit.allCases, id: \.self) { unit in
                        Text(Self.unitTitle(unit.label, unit.symbol)).tag(unit)
                    }
                }
            } footer: {
                Text(examples)
            }

            Section {
                Button("Use metric for everything") {
                    applyMetric()
                }
                Button("Use imperial for everything") {
                    applyImperial()
                }
            }
        }
        .pickerStyle(.menu)
        .settingsListStyle()
        .navigationTitle("Units")
        .navigationBarTitleDisplayMode(.inline)
    }

    /// "Metric", "Imperial", or "Mixed", for the Units row on the main Settings page. Kilopascals
    /// and hectopascals both count as metric.
    static func summary(for settings: AppSettings) -> String {
        let lengthMetric = settings.lengthUnit == LengthUnit.centimeters
        let weightMetric = settings.weightUnit == WeightUnit.kilograms
        let temperatureMetric = settings.temperatureUnit == TemperatureUnit.celsius
        let pressureMetric = settings.pressureUnit != PressureUnit.inchesOfMercury
        let speedMetric = settings.speedUnit == SpeedUnit.kilometresPerHour
        let depthMetric = settings.depthUnit == DepthUnit.meters
        let metricCount = [lengthMetric, weightMetric, temperatureMetric, pressureMetric, speedMetric, depthMetric]
            .filter { $0 }
            .count
        switch metricCount {
        case 6: return "Metric"
        case 0: return "Imperial"
        default: return "Mixed"
        }
    }

    /// "Centimetres (cm)", but "Hectopascals (millibars), hPa" so brackets do not stack up.
    private static func unitTitle(_ label: String, _ symbol: String) -> String {
        label.contains("(") ? "\(label), \(symbol)" : "\(label) (\(symbol))"
    }

    private var examples: String {
        let parts = [
            settings.length(45.5),
            settings.weight(1.8),
            settings.temperature(18),
            settings.pressure(1013.2),
            settings.speed(12),
            settings.depth(4.5)
        ]
        return "Looks like: " + parts.joined(separator: ", ") + ". Your log is stored in metric and converted for display."
    }

    /// No haptic: the pickers and the example line above change right away.
    private func applyMetric() {
        settings.lengthUnit = .centimeters
        settings.weightUnit = .kilograms
        settings.temperatureUnit = .celsius
        settings.pressureUnit = .kilopascals
        settings.speedUnit = .kilometresPerHour
        settings.depthUnit = .meters
    }

    private func applyImperial() {
        settings.lengthUnit = .inches
        settings.weightUnit = .pounds
        settings.temperatureUnit = .fahrenheit
        settings.pressureUnit = .inchesOfMercury
        settings.speedUnit = .milesPerHour
        settings.depthUnit = .feet
    }
}

/// Automatic weather from Open-Meteo and the phone's own barometer.
struct SettingsWeatherView: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings
        let hasBarometer = BarometerService.shared.isAvailable
        let barometerNote: String = hasBarometer
            ? "Reads the air pressure from the iPhone's own sensor during a trip. Works without signal."
            : "This iPhone has no barometer."
        List {
            Section {
                Toggle("Fetch weather automatically", isOn: $settings.autoFetchWeather)
            } footer: {
                Text("Weather comes from Open-Meteo when you have signal. Trips logged offline can be filled in later from the trip's page, up to 92 days back.")
            }

            Section {
                Toggle("Use the phone barometer", isOn: $settings.useBarometer)
                    .disabled(!hasBarometer)
            } footer: {
                Text(barometerNote)
            }
        }
        .settingsListStyle()
        .navigationTitle("Weather and pressure")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Units") {
    NavigationStack {
        SettingsUnitsView()
    }
    .environment(AppSettings.shared)
}
