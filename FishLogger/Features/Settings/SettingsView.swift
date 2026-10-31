import SwiftData
import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            Form {
                SettingsFishingProfileSection()
                SettingsDisplaySection()
                SettingsUnitsSection()
                SettingsLoggingSection()
                SettingsFavouritesLinkSection()
                SettingsPhotoIDSection()
                SettingsPermissionsSection()
                SettingsDataSection()
                SettingsResetSection()
                SettingsAboutSection()
            }
            .navigationTitle("Settings")
        }
    }
}

/// Title with an optional grey line underneath, for toggles and pickers that need a short explanation.
struct SettingsDetailLabel: View {
    let title: String
    var detail: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
            if let detail {
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: Your fishing

private struct SettingsFishingProfileSection: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        Section {
            NavigationLink {
                FishingProfileView()
            } label: {
                LabeledContent {
                    Text(settings.homeRegionsSummary)
                } label: {
                    Label("Your fishing", systemImage: "map")
                }
            }
        } footer: {
            Text("Where you fish and what you fish for. Sets which species show up.")
        }
    }
}

// MARK: Display

private struct SettingsDisplaySection: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings
        Section {
            // Menus rather than segmented controls: segments cannot wrap, so "Match iPhone" and
            // "Extra large" would truncate at the larger text sizes people pick here.
            Picker("Appearance", selection: $settings.appearance) {
                ForEach(AppearanceMode.allCases) { mode in
                    Text(mode.label).tag(mode)
                }
            }
            .pickerStyle(.menu)

            Picker("Text size", selection: $settings.textSize) {
                ForEach(TextSizeOption.allCases) { option in
                    Text(option.label).tag(option)
                }
            }
            .pickerStyle(.menu)

            Picker("Button size", selection: $settings.buttonSize) {
                ForEach(ButtonSize.allCases) { size in
                    Text(size.label).tag(size)
                }
            }
            .pickerStyle(.menu)
            SettingsSampleTile()
                .padding(.vertical, 4)

            Toggle(isOn: $settings.highContrast) {
                SettingsDetailLabel(
                    title: "High contrast",
                    detail: "Thicker outlines and stronger fills for glare. Also on when Increase Contrast is on in iPhone Settings."
                )
            }
            Toggle("Haptics", isOn: $settings.hapticsEnabled)
            Toggle(isOn: $settings.leftHanded) {
                SettingsDetailLabel(title: "Left-handed layout", detail: "Puts the camera buttons on the left.")
            }
            Toggle(isOn: $settings.keepScreenOn) {
                SettingsDetailLabel(
                    title: "Keep screen on during trips",
                    detail: "No Face ID or passcode for every fish. Uses more battery."
                )
            }
        } header: {
            Text("Display")
        }
    }
}

/// A quick log tile drawn at the chosen button size, so the setting is easy to judge.
private struct SettingsSampleTile: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        let walleye = SpeciesCatalog.species(id: "walleye")
        VStack(spacing: 6) {
            SpeciesIcon(species: walleye, size: settings.buttonSize.iconSize)
            Text("Walleye")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .frame(minWidth: settings.buttonSize.tileMinWidth, minHeight: settings.buttonSize.tileHeight)
        .cardBackground(tint: walleye?.color)
        .frame(maxWidth: .infinity)
        .animation(.default, value: settings.buttonSize)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Sample tile, Walleye, \(settings.buttonSize.label) buttons")
    }
}

// MARK: Units

private struct SettingsUnitsSection: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings
        Section {
            Picker("Length", selection: $settings.lengthUnit) {
                ForEach(LengthUnit.allCases) { unit in
                    Text(unitTitle(unit.label, unit.symbol)).tag(unit)
                }
            }
            Picker("Weight", selection: $settings.weightUnit) {
                ForEach(WeightUnit.allCases) { unit in
                    Text(unitTitle(unit.label, unit.symbol)).tag(unit)
                }
            }
            Picker("Temperature", selection: $settings.temperatureUnit) {
                ForEach(TemperatureUnit.allCases) { unit in
                    Text(unitTitle(unit.label, unit.symbol)).tag(unit)
                }
            }
            Picker("Pressure", selection: $settings.pressureUnit) {
                ForEach(PressureUnit.allCases) { unit in
                    Text(unitTitle(unit.label, unit.symbol)).tag(unit)
                }
            }
            Picker("Wind speed", selection: $settings.speedUnit) {
                ForEach(SpeedUnit.allCases) { unit in
                    Text(unitTitle(unit.label, unit.symbol)).tag(unit)
                }
            }
            Picker("Depth", selection: $settings.depthUnit) {
                ForEach(DepthUnit.allCases) { unit in
                    Text(unitTitle(unit.label, unit.symbol)).tag(unit)
                }
            }

            HStack(spacing: 12) {
                Button {
                    applyMetric()
                } label: {
                    Text("All metric")
                        .frame(maxWidth: .infinity)
                }
                Button {
                    applyImperial()
                } label: {
                    Text("All imperial")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        } header: {
            Text("Units")
        } footer: {
            Text(examples)
        }
    }

    /// "Centimetres (cm)", but "Hectopascals (millibars), hPa" so brackets do not stack up.
    private func unitTitle(_ label: String, _ symbol: String) -> String {
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

// MARK: Logging

private struct SettingsLoggingSection: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings
        let hasBarometer = BarometerService.shared.isAvailable
        Section {
            Picker(selection: $settings.sizeEntryMode) {
                ForEach(SizeEntryMode.allCases) { mode in
                    Text(mode.label).tag(mode)
                }
            } label: {
                SettingsDetailLabel(title: "Size entry", detail: "Show first in the catch editor")
            }
            Toggle("Tag catches with location", isOn: $settings.tagCatchLocation)
            Toggle(isOn: $settings.useBarometer) {
                SettingsDetailLabel(
                    title: "Use the phone barometer",
                    detail: hasBarometer ? nil : "This iPhone has no barometer."
                )
            }
            .disabled(!hasBarometer)
            Toggle("Fetch weather automatically", isOn: $settings.autoFetchWeather)
        } header: {
            Text("Logging")
        } footer: {
            Text("Weather comes from Open-Meteo when you have signal. Trips logged offline can be filled in later from the trip's page, up to 92 days back.")
        }
    }
}

// MARK: Favourites

private struct SettingsFavouritesLinkSection: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        Section {
            NavigationLink {
                SettingsFavouritesView()
            } label: {
                LabeledContent("Favourite species", value: summary)
            }
        } footer: {
            Text("Favourites always show in the quick log grid, in the order you set.")
        }
    }

    private var summary: String {
        let count = settings.favouriteSpeciesIDs.count
        return count == 0 ? "None" : count.formatted()
    }
}

// MARK: Reset

private struct SettingsResetSection: View {
    @Environment(AppSettings.self) private var settings
    @State private var confirmingReset = false

    var body: some View {
        Section {
            Button("Reset all settings", role: .destructive) {
                confirmingReset = true
            }
            .confirmationDialog("Reset all settings?", isPresented: $confirmingReset, titleVisibility: .visible) {
                Button("Reset settings", role: .destructive) {
                    settings.resetAll()
                    Haptics.warning()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Display, units, logging, and Photo ID settings go back to the defaults. Your trips, favourites, and API key stay.")
            }
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(AppModelContainer.inMemory())
        .environment(AppSettings.shared)
}
