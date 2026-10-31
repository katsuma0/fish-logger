import SwiftUI
import UIKit

/// Plain values for the logged confirmation, so it never reads a model that Undo just deleted.
struct TodayLoggedInfo: Equatable {
    let catchID: UUID
    /// New for every log, so a second fish restarts the timer even when it is the same species.
    let token: UUID
    let title: String
    let subtitle: String
    let species: Species?
    var sizeLabel: String?
    var hasPhoto: Bool
}

/// One-row confirmation after a log: species, "Walleye logged" with the trip count, then Size, Photo
/// and Undo. It floats over the top of the screen, where the trip header is, so it never pushes the
/// tiles down or sits where the thumb is logging the next fish.
struct TodayLoggedBanner: View {
    let info: TodayLoggedInfo
    /// True while a sheet or the camera is up, so the confirmation is still there afterwards.
    let isPaused: Bool
    let onSize: () -> Void
    let onPhoto: () -> Void
    let onUndo: () -> Void
    let onClose: () -> Void

    @Environment(AppSettings.self) private var settings
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    @Environment(\.accessibilitySwitchControlEnabled) private var switchControlEnabled
    @ScaledMetric(relativeTo: .subheadline) private var iconSize: CGFloat = 30
    /// The icon plus the longest species word ("Pumpkinseed") on one line. Any narrower and the title
    /// breaks mid-word, so the banner stacks instead.
    @ScaledMetric(relativeTo: .subheadline) private var minSummaryWidth: CGFloat = 140
    /// Off for a moment after each log, so a quick second tap meant for a tile is not caught here.
    @State private var acceptsTaps = false

    private static let visibleSeconds: UInt64 = 6
    private static let armDelayNanoseconds: UInt64 = 600_000_000

    init(
        info: TodayLoggedInfo,
        isPaused: Bool,
        onSize: @escaping () -> Void,
        onPhoto: @escaping () -> Void,
        onUndo: @escaping () -> Void,
        onClose: @escaping () -> Void
    ) {
        self.info = info
        self.isPaused = isPaused
        self.onSize = onSize
        self.onPhoto = onPhoto
        self.onUndo = onUndo
        self.onClose = onClose
    }

    var body: some View {
        let strong = settings.usesStrongContrast(colorSchemeContrast)

        // One row while the summary keeps room for a whole species word next to the buttons. Larger
        // text, larger buttons, a size label, or the Close button that VoiceOver and Switch Control
        // add can take that room, and then the buttons go on a line of their own.
        ViewThatFits(in: .horizontal) {
            if !dynamicTypeSize.isAccessibilitySize {
                HStack(alignment: .center, spacing: 8) {
                    // Measured at the floor, not the title on one line, so normal sizes keep the row.
                    summary
                        .frame(idealWidth: minSummaryWidth)
                    buttons(stretch: false)
                }
            }
            VStack(alignment: .leading, spacing: 8) {
                summary
                buttons(stretch: true)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .fill(strong ? AnyShapeStyle(Theme.cardBackground) : AnyShapeStyle(Material.regular))
                .shadow(color: Color.black.opacity(0.18), radius: 10, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .strokeBorder(strong ? Color.primary : Color.clear, lineWidth: 2)
        )
        .allowsHitTesting(acceptsTaps)
        .accessibilityElement(children: .contain)
        .accessibilityAction(.escape) { onClose() }
        .task(id: info.token) {
            await armAfterDelay()
        }
        .task(id: TodayBannerTimerKey(token: info.token, isPaused: isPaused, assistive: usesAssistiveTech)) {
            await hideAfterDelay()
        }
    }

    private var summary: some View {
        HStack(alignment: .center, spacing: 10) {
            SpeciesIcon(species: info.species, size: iconSize)
            VStack(alignment: .leading, spacing: 0) {
                Text(info.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(info.subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private func buttons(stretch: Bool) -> some View {
        HStack(spacing: 4) {
            barButton(
                title: info.sizeLabel ?? "Size",
                systemImage: "ruler",
                spoken: info.sizeLabel.map { "Size, \($0)" } ?? "Set size",
                hint: "Picks the size of this fish",
                stretch: stretch,
                action: onSize
            )
            barButton(
                title: "Photo",
                systemImage: info.hasPhoto ? "checkmark.circle.fill" : "camera",
                spoken: info.hasPhoto ? "Add another photo" : "Add photo",
                hint: "Takes a photo of this fish",
                stretch: stretch,
                action: onPhoto
            )
            barButton(
                title: "Undo",
                systemImage: "arrow.uturn.backward",
                role: .destructive,
                spoken: "Undo",
                hint: "Removes this catch",
                stretch: stretch,
                action: onUndo
            )
            if usesAssistiveTech {
                barButton(
                    title: "Close",
                    systemImage: "xmark",
                    spoken: "Close",
                    hint: "Hides this message",
                    stretch: stretch,
                    action: onClose
                )
            }
        }
        .fixedSize(horizontal: !stretch, vertical: false)
    }

    private func barButton(
        title: String,
        systemImage: String,
        role: ButtonRole? = nil,
        spoken: String,
        hint: String,
        stretch: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(role: role, action: action) {
            VStack(spacing: 2) {
                Image(systemName: systemImage)
                    .font(.body.weight(.semibold))
                    .accessibilityHidden(true)
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 4)
            .frame(
                minWidth: settings.buttonSize.minTapSize,
                maxWidth: stretch ? .infinity : nil,
                minHeight: settings.buttonSize.minTapSize
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
        .accessibilityLabel(spoken)
        .accessibilityHint(hint)
    }

    /// VoiceOver and Switch Control users need as long as they like, so nothing hides on them.
    private var usesAssistiveTech: Bool {
        voiceOverEnabled || switchControlEnabled
    }

    private func armAfterDelay() async {
        acceptsTaps = false
        try? await Task.sleep(nanoseconds: Self.armDelayNanoseconds)
        guard !Task.isCancelled else { return }
        acceptsTaps = true
    }

    private func hideAfterDelay() async {
        guard !isPaused, !usesAssistiveTech else { return }
        guard !UIAccessibility.isVoiceOverRunning, !UIAccessibility.isSwitchControlRunning else { return }
        try? await Task.sleep(nanoseconds: Self.visibleSeconds * 1_000_000_000)
        guard !Task.isCancelled else { return }
        onClose()
    }
}

/// Restarts the hide timer for a new fish, when a sheet closes, or when VoiceOver turns on or off.
private struct TodayBannerTimerKey: Equatable {
    let token: UUID
    let isPaused: Bool
    let assistive: Bool
}
