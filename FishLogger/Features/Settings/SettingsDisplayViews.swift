import SwiftUI
import UIKit

/// Appearance, text size, and button size, with a sample quick log tile drawn at the chosen size.
struct SettingsDisplayView: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings
        List {
            // Menus rather than segmented controls: segments cannot wrap, so "Match iPhone" and
            // "Extra large" would truncate at the larger text sizes people pick here.
            Section {
                Picker("Appearance", selection: $settings.appearance) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                .pickerStyle(.menu)
            } footer: {
                Text("Match iPhone follows Light or Dark in iPhone Settings.")
            }

            Section {
                Picker("Text size", selection: $settings.textSize) {
                    ForEach(TextSizeOption.allCases) { option in
                        Text(option.label).tag(option)
                    }
                }
                .pickerStyle(.menu)
            } footer: {
                Text("Match iPhone uses the text size set in iPhone Settings. The other sizes apply only in this app.")
            }

            Section {
                Picker("Button size", selection: $settings.buttonSize) {
                    ForEach(ButtonSize.allCases) { size in
                        Text(size.label).tag(size)
                    }
                }
                .pickerStyle(.menu)
                SettingsSampleTile()
                    // The screen colour behind the tile, so it shows the way it does on Today.
                    .listRowBackground(Color(uiColor: .systemGroupedBackground))
            } footer: {
                Text("Bigger buttons are easier to hit with wet or cold hands. The tile shows a quick log button at this size.")
            }
        }
        .settingsListStyle()
        .navigationTitle("Display and text size")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// A quick log tile drawn like the ones on Today, a plain name on a grouped card, at the chosen
/// button size so the setting is easy to judge.
private struct SettingsSampleTile: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    /// Same measures as the Today grid, so the sample grows with the text the same way.
    @ScaledMetric(relativeTo: .headline) private var baseTileHeight: CGFloat = 92
    @ScaledMetric(relativeTo: .caption) private var countRoom: CGFloat = 24

    var body: some View {
        let buttonSize = settings.buttonSize
        // Today widens its tiles from xLarge text up, and fills the row at accessibility sizes.
        let widthScale: CGFloat = dynamicTypeSize >= .xLarge ? 1.25 : 1
        let maxTileWidth: CGFloat? = dynamicTypeSize.isAccessibilitySize ? CGFloat.infinity : nil
        Text("Walleye")
            .font(.headline)
            .foregroundStyle(.primary)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 6)
            .padding(.vertical, countRoom)
            .frame(
                minWidth: buttonSize.tileMinWidth * widthScale,
                maxWidth: maxTileWidth,
                minHeight: baseTileHeight * buttonSize.scale
            )
            .cardBackground()
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .animation(.default, value: buttonSize)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Sample tile, Walleye, \(buttonSize.label) buttons")
    }
}

/// High contrast, left-handed layout, and haptics.
struct SettingsAccessibilityView: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings
        List {
            Section {
                Toggle("High contrast", isOn: $settings.highContrast)
            } footer: {
                Text("Thicker outlines and stronger fills for glare on the water. Also on when Increase Contrast is on in iPhone Settings.")
            }

            Section {
                Toggle("Left-handed layout", isOn: $settings.leftHanded)
            } footer: {
                Text("Moves the Photo ID camera button to the left, on the thumb side.")
            }

            Section {
                Toggle("Haptics", isOn: $settings.hapticsEnabled)
            } footer: {
                Text("A short buzz confirms each fish you log, so you know without looking.")
            }
        }
        .settingsListStyle()
        .navigationTitle("Accessibility")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Display") {
    NavigationStack {
        SettingsDisplayView()
    }
    .environment(AppSettings.shared)
}

#Preview("Accessibility") {
    NavigationStack {
        SettingsAccessibilityView()
    }
    .environment(AppSettings.shared)
}
