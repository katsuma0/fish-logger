import SwiftData
import SwiftUI
import UIKit

/// The Settings tab, laid out like the iOS Settings app: rows with small coloured icons, grouped
/// into sections, each opening a page for one topic.
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
                    SettingsLinkRow("Permissions", systemImage: "location.fill", color: .systemGray) {
                        SettingsPermissionsView()
                    }
                    SettingsLinkRow("Data", systemImage: "externaldrive.fill", color: .systemGreen) {
                        SettingsDataView()
                    }
                }

                Section {
                    SettingsLinkRow("About", systemImage: "info.circle", color: .systemGray) {
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

/// Icon and title, with the value in grey on the right when there is one, like the Wi-Fi row in
/// iOS Settings. VoiceOver reads the title, then the value.
struct SettingsRowLabel: View {
    private let title: String
    private let systemImage: String
    private let color: UIColor
    private let value: String?

    init(_ title: String, systemImage: String, color: UIColor, value: String? = nil) {
        self.title = title
        self.systemImage = systemImage
        self.color = color
        self.value = value
    }

    var body: some View {
        if let value {
            LabeledContent {
                Text(value)
            } label: {
                titleAndIcon
            }
        } else {
            titleAndIcon
        }
    }

    private var titleAndIcon: some View {
        Label {
            Text(title)
        } icon: {
            SettingsIcon(systemImage: systemImage, color: color)
        }
    }
}

/// A white symbol on a small rounded square in a system colour, the way iOS Settings marks its
/// rows. It grows a little with the text size, and high contrast switches to the darker system
/// colours that Increase Contrast uses.
struct SettingsIcon: View {
    private let systemImage: String
    private let color: UIColor

    @Environment(AppSettings.self) private var settings
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @ScaledMetric(relativeTo: .body) private var scaledSide: CGFloat = 29

    init(systemImage: String, color: UIColor) {
        self.systemImage = systemImage
        self.color = color
    }

    var body: some View {
        // Capped so the icon never crowds the title at the largest accessibility sizes.
        let side = min(scaledSide, 44)
        let strong = settings.usesStrongContrast(colorSchemeContrast)
        Image(systemName: systemImage)
            .symbolRenderingMode(.monochrome)
            .font(.system(size: side * 0.6, weight: .medium))
            .foregroundStyle(Color.white)
            .frame(width: side, height: side)
            .background(
                RoundedRectangle(cornerRadius: side * 0.24, style: .continuous)
                    .fill(Self.fill(color, strong: strong))
            )
            .accessibilityHidden(true)
    }

    /// The system colour as is, or its Increase Contrast version when the app's High contrast is on.
    /// With the iPhone switch on, the system colour already resolves to that version.
    private static func fill(_ base: UIColor, strong: Bool) -> Color {
        guard strong else { return Color(uiColor: base) }
        return Color(uiColor: UIColor { traits in
            base.resolvedColor(with: traits.modifyingTraits { $0.accessibilityContrast = .high })
        })
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
