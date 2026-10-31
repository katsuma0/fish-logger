import Observation
import SwiftUI

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var label: String {
        switch self {
        case .system: "Match iPhone"
        case .light: "Light"
        case .dark: "Dark"
        }
    }
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

/// How big tap targets are. Separate from text size because wet or gloved hands need big
/// buttons even when the text is fine.
enum ButtonSize: String, CaseIterable, Identifiable {
    case small, medium, large, extraLarge
    var id: String { rawValue }
    var label: String {
        switch self {
        case .small: "Small"
        case .medium: "Medium"
        case .large: "Large"
        case .extraLarge: "Extra large"
        }
    }
    var scale: CGFloat {
        switch self {
        case .small: 0.85
        case .medium: 1.0
        case .large: 1.25
        case .extraLarge: 1.5
        }
    }
    /// Height of a species tile in the quick log grid.
    var tileHeight: CGFloat { 92 * scale }
    /// Minimum width of a quick log tile; the grid fits as many as it can.
    var tileMinWidth: CGFloat { 104 * scale }
    /// Height for primary buttons like Start trip or Log catch.
    var primaryButtonHeight: CGFloat { 54 * scale }
    /// Minimum tap target for secondary controls. Never below Apple's 44 pt.
    var minTapSize: CGFloat { max(44, 44 * scale) }
    var iconSize: CGFloat { 30 * scale }
}

enum TextSizeOption: String, CaseIterable, Identifiable {
    case system, small, medium, large, extraLarge, huge
    var id: String { rawValue }
    var label: String {
        switch self {
        case .system: "Match iPhone"
        case .small: "Small"
        case .medium: "Medium"
        case .large: "Large"
        case .extraLarge: "Extra large"
        case .huge: "Huge"
        }
    }
    var dynamicTypeSize: DynamicTypeSize? {
        switch self {
        case .system: nil
        case .small: .small
        case .medium: .large
        case .large: .xLarge
        case .extraLarge: .xxxLarge
        case .huge: .accessibility2
        }
    }
}

enum SizeEntryMode: String, CaseIterable, Identifiable {
    case category, exact
    var id: String { rawValue }
    var label: String { self == .category ? "Size class" : "Exact measurement" }
}

/// App preferences backed by UserDefaults. Reads go straight to UserDefaults so App Intents and
/// the app always agree, and `access`/`withMutation` keep SwiftUI views updating.
@Observable
final class AppSettings {
    static let shared = AppSettings()

    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    enum Keys {
        static let appearance = "appearance"
        static let buttonSize = "buttonSize"
        static let textSize = "textSize"
        static let highContrast = "highContrast"
        static let hapticsEnabled = "hapticsEnabled"
        static let leftHanded = "leftHanded"
        static let keepScreenOn = "keepScreenOn"
        static let lengthUnit = "lengthUnit"
        static let weightUnit = "weightUnit"
        static let temperatureUnit = "temperatureUnit"
        static let pressureUnit = "pressureUnit"
        static let speedUnit = "speedUnit"
        static let depthUnit = "depthUnit"
        static let sizeEntryMode = "sizeEntryMode"
        static let autoFetchWeather = "autoFetchWeather"
        static let tagCatchLocation = "tagCatchLocation"
        static let useBarometer = "useBarometer"
        static let favouriteSpeciesIDs = "favouriteSpeciesIDs"
        static let photoIDEnabled = "photoIDEnabled"
        static let claudeModel = "claudeModel"
        static let hasSeenWelcome = "hasSeenWelcome"
        static let homeRegions = "homeRegions"
        static let targetGroups = "targetGroups"
    }

    static let defaultClaudeModel = "claude-opus-5-5"

    // MARK: Appearance and accessibility

    var appearance: AppearanceMode {
        get { access(keyPath: \.appearance); return enumValue(Keys.appearance, default: .system) }
        set { withMutation(keyPath: \.appearance) { defaults.set(newValue.rawValue, forKey: Keys.appearance) } }
    }

    var buttonSize: ButtonSize {
        get { access(keyPath: \.buttonSize); return enumValue(Keys.buttonSize, default: .medium) }
        set { withMutation(keyPath: \.buttonSize) { defaults.set(newValue.rawValue, forKey: Keys.buttonSize) } }
    }

    var textSize: TextSizeOption {
        get { access(keyPath: \.textSize); return enumValue(Keys.textSize, default: .system) }
        set { withMutation(keyPath: \.textSize) { defaults.set(newValue.rawValue, forKey: Keys.textSize) } }
    }

    /// Stronger borders and solid fills, for glare on the water.
    var highContrast: Bool {
        get { access(keyPath: \.highContrast); return boolValue(Keys.highContrast, default: false) }
        set { withMutation(keyPath: \.highContrast) { defaults.set(newValue, forKey: Keys.highContrast) } }
    }

    var hapticsEnabled: Bool {
        get { access(keyPath: \.hapticsEnabled); return boolValue(Keys.hapticsEnabled, default: true) }
        set { withMutation(keyPath: \.hapticsEnabled) { defaults.set(newValue, forKey: Keys.hapticsEnabled) } }
    }

    /// Moves floating buttons to the left edge for left-thumb use.
    var leftHanded: Bool {
        get { access(keyPath: \.leftHanded); return boolValue(Keys.leftHanded, default: false) }
        set { withMutation(keyPath: \.leftHanded) { defaults.set(newValue, forKey: Keys.leftHanded) } }
    }

    /// Stops auto-lock while a trip is active. Costs battery, so it is off by default.
    var keepScreenOn: Bool {
        get { access(keyPath: \.keepScreenOn); return boolValue(Keys.keepScreenOn, default: false) }
        set { withMutation(keyPath: \.keepScreenOn) { defaults.set(newValue, forKey: Keys.keepScreenOn) } }
    }

    // MARK: Units. Defaults follow Environment Canada: metric, pressure in kPa.

    var lengthUnit: LengthUnit {
        get { access(keyPath: \.lengthUnit); return enumValue(Keys.lengthUnit, default: .centimeters) }
        set { withMutation(keyPath: \.lengthUnit) { defaults.set(newValue.rawValue, forKey: Keys.lengthUnit) } }
    }

    var weightUnit: WeightUnit {
        get { access(keyPath: \.weightUnit); return enumValue(Keys.weightUnit, default: .kilograms) }
        set { withMutation(keyPath: \.weightUnit) { defaults.set(newValue.rawValue, forKey: Keys.weightUnit) } }
    }

    var temperatureUnit: TemperatureUnit {
        get { access(keyPath: \.temperatureUnit); return enumValue(Keys.temperatureUnit, default: .celsius) }
        set { withMutation(keyPath: \.temperatureUnit) { defaults.set(newValue.rawValue, forKey: Keys.temperatureUnit) } }
    }

    var pressureUnit: PressureUnit {
        get { access(keyPath: \.pressureUnit); return enumValue(Keys.pressureUnit, default: .kilopascals) }
        set { withMutation(keyPath: \.pressureUnit) { defaults.set(newValue.rawValue, forKey: Keys.pressureUnit) } }
    }

    var speedUnit: SpeedUnit {
        get { access(keyPath: \.speedUnit); return enumValue(Keys.speedUnit, default: .kilometresPerHour) }
        set { withMutation(keyPath: \.speedUnit) { defaults.set(newValue.rawValue, forKey: Keys.speedUnit) } }
    }

    var depthUnit: DepthUnit {
        get { access(keyPath: \.depthUnit); return enumValue(Keys.depthUnit, default: .meters) }
        set { withMutation(keyPath: \.depthUnit) { defaults.set(newValue.rawValue, forKey: Keys.depthUnit) } }
    }

    // MARK: Logging behaviour

    /// Which size input the catch editor shows first.
    var sizeEntryMode: SizeEntryMode {
        get { access(keyPath: \.sizeEntryMode); return enumValue(Keys.sizeEntryMode, default: .category) }
        set { withMutation(keyPath: \.sizeEntryMode) { defaults.set(newValue.rawValue, forKey: Keys.sizeEntryMode) } }
    }

    var autoFetchWeather: Bool {
        get { access(keyPath: \.autoFetchWeather); return boolValue(Keys.autoFetchWeather, default: true) }
        set { withMutation(keyPath: \.autoFetchWeather) { defaults.set(newValue, forKey: Keys.autoFetchWeather) } }
    }

    var tagCatchLocation: Bool {
        get { access(keyPath: \.tagCatchLocation); return boolValue(Keys.tagCatchLocation, default: true) }
        set { withMutation(keyPath: \.tagCatchLocation) { defaults.set(newValue, forKey: Keys.tagCatchLocation) } }
    }

    var useBarometer: Bool {
        get { access(keyPath: \.useBarometer); return boolValue(Keys.useBarometer, default: true) }
        set { withMutation(keyPath: \.useBarometer) { defaults.set(newValue, forKey: Keys.useBarometer) } }
    }

    /// Pinned species always show in the quick log grid, in this order.
    var favouriteSpeciesIDs: [String] {
        get { access(keyPath: \.favouriteSpeciesIDs); return defaults.stringArray(forKey: Keys.favouriteSpeciesIDs) ?? [] }
        set { withMutation(keyPath: \.favouriteSpeciesIDs) { defaults.set(newValue, forKey: Keys.favouriteSpeciesIDs) } }
    }

    func isFavourite(_ speciesID: String) -> Bool { favouriteSpeciesIDs.contains(speciesID) }

    func toggleFavourite(_ speciesID: String) {
        var ids = favouriteSpeciesIDs
        if let index = ids.firstIndex(of: speciesID) { ids.remove(at: index) } else { ids.append(speciesID) }
        favouriteSpeciesIDs = ids
    }

    // MARK: Photo ID

    /// Sends photos to Claude for species ID when online and a key is saved.
    var photoIDEnabled: Bool {
        get { access(keyPath: \.photoIDEnabled); return boolValue(Keys.photoIDEnabled, default: true) }
        set { withMutation(keyPath: \.photoIDEnabled) { defaults.set(newValue, forKey: Keys.photoIDEnabled) } }
    }

    var claudeModel: String {
        get {
            access(keyPath: \.claudeModel)
            let stored = defaults.string(forKey: Keys.claudeModel)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return stored.isEmpty ? Self.defaultClaudeModel : stored
        }
        set { withMutation(keyPath: \.claudeModel) { defaults.set(newValue, forKey: Keys.claudeModel) } }
    }

    // MARK: Where and what you fish

    /// Regions picked during setup. Empty means all of North America.
    var homeRegions: Set<FishingRegion> {
        get {
            access(keyPath: \.homeRegions)
            let raw = defaults.stringArray(forKey: Keys.homeRegions) ?? []
            return Set(raw.compactMap(FishingRegion.init(rawValue:)))
        }
        set {
            withMutation(keyPath: \.homeRegions) {
                defaults.set(newValue.map(\.rawValue).sorted(), forKey: Keys.homeRegions)
            }
        }
    }

    /// Kinds of fish picked during setup. Empty means everything.
    var targetGroups: Set<SpeciesGroup> {
        get {
            access(keyPath: \.targetGroups)
            let raw = defaults.stringArray(forKey: Keys.targetGroups) ?? []
            return Set(raw.compactMap(SpeciesGroup.init(rawValue:)))
        }
        set {
            withMutation(keyPath: \.targetGroups) {
                defaults.set(newValue.map(\.rawValue).sorted(), forKey: Keys.targetGroups)
            }
        }
    }

    /// Species for the chosen regions, alphabetical. Every species when no region is set.
    var regionalSpecies: [Species] { SpeciesCatalog.available(in: homeRegions) }

    /// Short summary for Settings, e.g. "Ontario" or "Ontario and 2 more".
    var homeRegionsSummary: String {
        let names = FishingRegion.allCases.filter { homeRegions.contains($0) }.map(\.label)
        switch names.count {
        case 0: return "All of North America"
        case 1: return names[0]
        default: return "\(names[0]) and \(names.count - 1) more"
        }
    }

    /// Set once the first-launch questions are answered or skipped.
    var hasSeenWelcome: Bool {
        get { access(keyPath: \.hasSeenWelcome); return boolValue(Keys.hasSeenWelcome, default: false) }
        set { withMutation(keyPath: \.hasSeenWelcome) { defaults.set(newValue, forKey: Keys.hasSeenWelcome) } }
    }

    // MARK: Formatting shortcuts, so views do not repeat unit plumbing

    func length(_ cm: Double) -> String { lengthUnit.format(cm) }
    func weight(_ kg: Double) -> String { weightUnit.format(kg) }
    func temperature(_ c: Double) -> String { temperatureUnit.format(c) }
    func pressure(_ hPa: Double) -> String { pressureUnit.format(hPa) }
    func speed(_ kmh: Double) -> String { speedUnit.format(kmh) }
    func depth(_ m: Double) -> String { depthUnit.format(m) }

    /// "40 to 55 cm", "under 30 cm", "70 cm and up" for a species size class.
    func lengthRangeLabel(_ species: Species, _ sizeClass: SizeClass) -> String {
        let range = species.lengthRange(for: sizeClass)
        let unit = lengthUnit
        switch (range.lower, range.upper) {
        case let (lower?, upper?):
            return "\(unit.formatNumber(lower)) to \(unit.format(upper))"
        case let (nil, upper?):
            return "under \(unit.format(upper))"
        case let (lower?, nil):
            return "\(unit.format(lower)) and up"
        default:
            return ""
        }
    }

    /// Clears every preference. Used by the reset button in Settings.
    func resetAll() {
        let keys = [
            Keys.appearance, Keys.buttonSize, Keys.textSize, Keys.highContrast, Keys.hapticsEnabled,
            Keys.leftHanded, Keys.keepScreenOn, Keys.lengthUnit, Keys.weightUnit, Keys.temperatureUnit,
            Keys.pressureUnit, Keys.speedUnit, Keys.depthUnit, Keys.sizeEntryMode, Keys.autoFetchWeather,
            Keys.tagCatchLocation, Keys.useBarometer, Keys.photoIDEnabled, Keys.claudeModel
        ]
        for key in keys { defaults.removeObject(forKey: key) }
        // One mutation per property so every view watching settings refreshes.
        appearance = appearance
        buttonSize = buttonSize
        textSize = textSize
        highContrast = highContrast
        hapticsEnabled = hapticsEnabled
        leftHanded = leftHanded
        keepScreenOn = keepScreenOn
        lengthUnit = lengthUnit
        weightUnit = weightUnit
        temperatureUnit = temperatureUnit
        pressureUnit = pressureUnit
        speedUnit = speedUnit
        depthUnit = depthUnit
        sizeEntryMode = sizeEntryMode
        autoFetchWeather = autoFetchWeather
        tagCatchLocation = tagCatchLocation
        useBarometer = useBarometer
        photoIDEnabled = photoIDEnabled
        claudeModel = claudeModel
    }

    // MARK: Helpers

    private func enumValue<T: RawRepresentable>(_ key: String, default fallback: T) -> T where T.RawValue == String {
        guard let raw = defaults.string(forKey: key), let value = T(rawValue: raw) else { return fallback }
        return value
    }

    private func boolValue(_ key: String, default fallback: Bool) -> Bool {
        defaults.object(forKey: key) == nil ? fallback : defaults.bool(forKey: key)
    }
}
