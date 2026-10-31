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

/// Stock iOS look: system grouped backgrounds (true black with grey cards in dark mode), system blue
/// for the accent, and the system font in its text styles.
enum Theme {
    /// Card fill: white on light grey, iOS grey on black in dark mode.
    static let cardBackground = Color(uiColor: .secondarySystemGroupedBackground)
    static let screenBackground = Color(uiColor: .systemGroupedBackground)
    static let cornerRadius: CGFloat = 12
    /// System blue for filled backgrounds behind white text. Asset "AccentFill". It matches
    /// AccentColor, except with Increase Contrast on in dark mode, where it stays on the deep blue
    /// so white text still reads. Keep AccentColor for tinted text and icons.
    static let accentFill = Color("AccentFill")
    /// The deep blue iOS uses with Increase Contrast on. White text on it clears 7:1.
    static let strongAccentFill = Color(hex: 0x0040DD)

    /// Fill behind white text. High contrast, from the app setting or the system switch, gets the
    /// deep blue in light and dark mode.
    static func accentFillColor(strong: Bool) -> Color {
        strong ? strongAccentFill : accentFill
    }
}

extension AppSettings {
    /// High contrast from the app setting or the system Increase Contrast switch.
    func usesStrongContrast(_ contrast: ColorSchemeContrast) -> Bool {
        highContrast || contrast == .increased
    }
}

/// Rounded card used for tiles and summary blocks, in the iOS grouped card grey. High contrast adds a
/// hard border. A tint is for selection states, not for colouring cards by species.
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

/// Big full-width button for the main action on a screen, drawn like an iOS filled button: system
/// blue, white headline text, and a dimmed fill while pressed. Height follows the Button size setting.
/// High contrast swaps in the deep blue and adds a border. A disabled button goes grey.
struct PrimaryActionButtonStyle: ButtonStyle {
    @Environment(AppSettings.self) private var settings
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    /// Nil uses system blue.
    private let tint: Color?

    init(tint: Color? = nil) {
        self.tint = tint
    }

    func makeBody(configuration: Configuration) -> some View {
        let strong = settings.usesStrongContrast(colorSchemeContrast)
        let shape = RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
        let fill: Color = isEnabled
            ? (tint ?? Theme.accentFillColor(strong: strong))
            : Color(uiColor: .tertiarySystemFill)
        return configuration.label
            .font(.headline)
            .multilineTextAlignment(.center)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, minHeight: settings.buttonSize.primaryButtonHeight)
            .padding(.horizontal, 16)
            .foregroundStyle(isEnabled ? Color.white : Color(uiColor: .secondaryLabel))
            .background(
                shape
                    .fill(fill)
                    .opacity(configuration.isPressed ? 0.7 : 1)
            )
            .overlay(
                shape.strokeBorder(strong ? Color.primary : Color.clear, lineWidth: 2)
            )
            .contentShape(shape)
    }
}

/// Small species badge in the style of an iOS Settings icon: a flat rounded square in the species
/// colour with a white fish. Used beside species names in lists.
struct SpeciesIcon: View {
    let species: Species?
    var size: CGFloat = 36

    var body: some View {
        let tint = species?.color ?? Color(uiColor: .systemGray)
        RoundedRectangle(cornerRadius: size * 0.225, style: .continuous)
            .fill(tint)
            .frame(width: size, height: size)
            .overlay(
                Image(systemName: "fish.fill")
                    .font(.system(size: size * 0.5, weight: .medium))
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
