import SwiftData
import SwiftUI
import UIKit

/// The Settings tab, laid out like the iOS Settings app: rows with small coloured icons, grouped
/// into sections, each opening a page for one topic. Every row icon is a filled symbol in white.
struct SettingsView: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        NavigationStack {
            List {
                Section {
                    SettingsLinkRow("Your fishing", systemImage: "map.fill", color: .systemBlue, value: settings.homeRegionsSummary) {
                        FishingProfileView()
                    }
                    SettingsLinkRow("Favourites", systemImage: "star.fill", color: .systemYellow, value: favouritesSummary) {
                        SettingsFavouritesView()
                    }
                }

                Section {
                    SettingsLinkRow("Display and text size", systemImage: "textformat.size", color: .systemBlue) {
                        SettingsDisplayView()
                    }
                    SettingsLinkRow("Accessibility", systemImage: "accessibility", color: .systemBlue) {
                        SettingsAccessibilityView()
                    }
                }

                Section {
                    SettingsLinkRow("Logging", systemImage: "fish.fill", color: .systemGreen) {
                        SettingsLoggingView()
                    }
                    SettingsLinkRow("Units", systemImage: "ruler.fill", color: .systemOrange, value: SettingsUnitsView.summary(for: settings)) {
                        SettingsUnitsView()
                    }
                    SettingsLinkRow("Weather and pressure", systemImage: "cloud.sun.fill", color: .systemCyan) {
                        SettingsWeatherView()
                    }
                    SettingsPhotoIDRow()
                }

                Section {
                    SettingsLinkRow("Permissions", systemImage: "location.fill", color: .systemBlue) {
                        SettingsPermissionsView()
                    }
                    SettingsLinkRow("Data", systemImage: "externaldrive.fill", color: .systemGreen) {
                        SettingsDataView()
                    }
                }

                Section {
                    SettingsLinkRow("About", systemImage: "info.circle.fill", color: .systemGray) {
                        SettingsAboutView()
                    }
                }
            }
            .settingsListStyle()
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var favouritesSummary: String {
        let count = settings.favouriteSpeciesIDs.count
        return count == 0 ? "None" : count.formatted()
    }
}

// MARK: Rows

/// A Settings row that opens a page: icon, title, and an optional current value on the right.
struct SettingsLinkRow<Destination: View>: View {
    private let title: String
    private let systemImage: String
    private let color: UIColor
    private let value: String?
    private let destination: () -> Destination

    init(
        _ title: String,
        systemImage: String,
        color: UIColor,
        value: String? = nil,
        @ViewBuilder destination: @escaping () -> Destination
    ) {
        self.title = title
        self.systemImage = systemImage
        self.color = color
        self.value = value
        self.destination = destination
    }

    var body: some View {
        NavigationLink {
            destination()
        } label: {
            SettingsRowLabel(title, systemImage: systemImage, color: color, value: value)
        }
    }
}

/// One Settings row the way iOS Settings draws it: the icon, a fixed gap, then the title, with the
/// value in grey on the right when there is one, like the Wi-Fi row. The row separator starts under
/// the title, not under the icon. VoiceOver reads the title, then the value.
struct SettingsRowLabel: View {
    private let title: String
    private let systemImage: String
    private let color: UIColor
    private let value: String?

    /// Space between the icon and the title.
    private static let iconSpacing: CGFloat = 14

    init(_ title: String, systemImage: String, color: UIColor, value: String? = nil) {
        self.title = title
        self.systemImage = systemImage
        self.color = color
        self.value = value
    }

    var body: some View {
        HStack(spacing: Self.iconSpacing) {
            SettingsIcon(systemImage: systemImage, color: color)
            titleAndValue
                .alignmentGuide(.listRowSeparatorLeading) { dimensions in
                    dimensions[.leading]
                }
        }
    }

    @ViewBuilder
    private var titleAndValue: some View {
        if let value {
            LabeledContent {
                Text(value)
            } label: {
                Text(title)
            }
        } else {
            Text(title)
        }
    }
}

/// A white symbol on a rounded square in a system colour, the way iOS Settings marks its rows:
/// 29 points at the default text size, growing a little with larger text up to a cap. The square
/// keeps its size whatever the symbol, so wide symbols stay centred and every row lines up.
struct SettingsIcon: View {
    private let systemImage: String
    private let color: UIColor

    @Environment(AppSettings.self) private var settings
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @ScaledMetric(relativeTo: .body) private var scaledSide: CGFloat = 29

    /// Sizes from iOS Settings at the default text size.
    private static let baseSide: CGFloat = 29
    private static let baseCornerRadius: CGFloat = 6.5
    private static let baseSymbolSize: CGFloat = 17
    /// Largest the square gets, so it never crowds the title at the accessibility text sizes.
    private static let maximumSide: CGFloat = 40

    init(systemImage: String, color: UIColor) {
        self.systemImage = systemImage
        self.color = color
    }

    var body: some View {
        let side = min(max(scaledSide, Self.baseSide), Self.maximumSide)
        let scale = side / Self.baseSide
        RoundedRectangle(cornerRadius: Self.baseCornerRadius * scale, style: .continuous)
            .fill(fillColor)
            .frame(width: side, height: side)
            .overlay {
                Image(systemName: systemImage)
                    .symbolRenderingMode(.monochrome)
                    .font(.system(size: Self.baseSymbolSize * scale, weight: .medium))
                    .foregroundStyle(Color.white)
                    .frame(width: side, height: side)
            }
            .accessibilityHidden(true)
    }

    /// The plain system colour. High contrast, from the app setting or the iPhone switch, uses the
    /// deep Increase Contrast version from light mode in light and dark mode alike, so the white
    /// symbol stands out. The dark mode versions are lighter, which would fade the symbol.
    private var fillColor: Color {
        guard settings.usesStrongContrast(colorSchemeContrast) else {
            return Color(uiColor: color)
        }
        let deepTraits = UITraitCollection(userInterfaceStyle: .light)
            .modifyingTraits { $0.accessibilityContrast = .high }
        return Color(uiColor: color.resolvedColor(with: deepTraits))
    }
}

// MARK: Shared pieces

/// Every Settings page: an inset grouped list whose rows are at least as tall as the Button size
/// setting asks.
private struct SettingsListStyle: ViewModifier {
    @Environment(AppSettings.self) private var settings

    func body(content: Content) -> some View {
        content
            .listStyle(.insetGrouped)
            .environment(\.defaultMinListRowHeight, settings.buttonSize.minTapSize)
    }
}

extension View {
    /// Inset grouped list with rows sized for the Button size setting.
    func settingsListStyle() -> some View {
        modifier(SettingsListStyle())
    }
}

/// Title with an optional grey line underneath, for a control that needs a short note in the row
/// itself. Most Settings notes go in the section footer instead, as in iOS Settings.
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

#Preview {
    SettingsView()
        .modelContainer(AppModelContainer.inMemory())
        .environment(AppSettings.shared)
}
