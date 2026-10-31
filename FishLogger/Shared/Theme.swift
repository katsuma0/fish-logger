import SwiftUI
import UIKit

extension Color {
    /// 0xRRGGBB.
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

enum Theme {
    /// Card fill that holds up in both light and dark mode.
    static let cardBackground = Color(uiColor: .secondarySystemGroupedBackground)
    static let screenBackground = Color(uiColor: .systemGroupedBackground)
    static let cornerRadius: CGFloat = 14
    /// Accent for filled backgrounds behind white text. Darker than AccentColor so white text clears
    /// 4.5:1 in light and dark mode. Asset "AccentFill". Keep AccentColor for tinted text and icons.
    static let accentFill = Color("AccentFill")
}

extension AppSettings {
    /// High contrast from the app setting or the system Increase Contrast switch.
    func usesStrongContrast(_ contrast: ColorSchemeContrast) -> Bool {
        highContrast || contrast == .increased
    }
}

/// Rounded card used for tiles and summary blocks. High contrast swaps the soft fill for a hard border.
struct CardBackground: ViewModifier {
    @Environment(AppSettings.self) private var settings
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    var tint: Color? = nil

    func body(content: Content) -> some View {
        let strong = settings.usesStrongContrast(colorSchemeContrast)
        return content
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                    .fill(tint.map { $0.opacity(strong ? 0.35 : 0.15) } ?? Theme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                    .strokeBorder(strong ? Color.primary : Color.clear, lineWidth: strong ? 2 : 0)
            )
    }
}

extension View {
    func cardBackground(tint: Color? = nil) -> some View {
        modifier(CardBackground(tint: tint))
    }

    /// Applies the app's text size override, if any.
    @ViewBuilder
    func appTextSize(_ option: TextSizeOption) -> some View {
        if let size = option.dynamicTypeSize {
            dynamicTypeSize(size)
        } else {
            self
        }
    }
}

/// Big full-width button for the main action on a screen. Height follows the Button size setting.
/// The default fill is `Theme.accentFill`, which keeps white text readable in dark mode.
struct PrimaryActionButtonStyle: ButtonStyle {
    @Environment(AppSettings.self) private var settings
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    var tint: Color = Theme.accentFill

    func makeBody(configuration: Configuration) -> some View {
        let strong = settings.usesStrongContrast(colorSchemeContrast)
        return configuration.label
            .font(.headline)
            .multilineTextAlignment(.center)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, minHeight: settings.buttonSize.primaryButtonHeight)
            .padding(.horizontal, 16)
            .foregroundStyle(.white)
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                    .fill(isEnabled ? tint : Color.gray)
                    .opacity(configuration.isPressed ? 0.75 : 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                    .strokeBorder(strong ? Color.primary : Color.clear, lineWidth: 2)
            )
            .contentShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
    }
}

/// Shows a fish tinted with the species colour. Used everywhere a species appears.
struct SpeciesIcon: View {
    let species: Species?
    var size: CGFloat = 36

    var body: some View {
        let tint = species?.color ?? .gray
        RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
            .fill(tint.gradient)
            .frame(width: size, height: size)
            .overlay(
                Image(systemName: "fish.fill")
                    .font(.system(size: size * 0.5, weight: .semibold))
                    .foregroundStyle(.white)
            )
            .accessibilityHidden(true)
    }
}

/// Small label + value pair for condition readouts, e.g. a thermometer and "18°C".
struct ConditionChip: View {
    let systemImage: String
    let text: String
    var accessibilityLabel: String? = nil

    @Environment(AppSettings.self) private var settings
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    var body: some View {
        let strong = settings.usesStrongContrast(colorSchemeContrast)
        Label(text, systemImage: systemImage)
            .font(.subheadline)
            .labelStyle(.titleAndIcon)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color(uiColor: .tertiarySystemFill)))
            .overlay(Capsule().strokeBorder(strong ? Color.primary : Color.clear, lineWidth: 1))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityLabel ?? text)
    }
}
