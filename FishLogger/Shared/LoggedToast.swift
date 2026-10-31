import SwiftData
import SwiftUI
import UIKit

extension View {
    /// Bottom toast for a catch logged outside the Today screen: species icon, "Walleye logged",
    /// Undo. Undo deletes the catch through CatchLogger, and the trip too when logging that catch
    /// started it. Hides after 4 s, never while VoiceOver or Switch Control runs.
    /// Setting the binding to nil hides it.
    func loggedToast(_ fishCatch: Binding<FishCatch?>) -> some View {
        modifier(LoggedToastModifier(fishCatch: fishCatch))
    }
}

private struct LoggedToastModifier: ViewModifier {
    @Binding var fishCatch: FishCatch?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Copied when the toast appears, so it never reads a catch that was deleted somewhere else.
    @State private var shown: LoggedToastContent?

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if let shown {
                    LoggedToastView(content: shown, onUndo: undo, onClose: hide)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                        .transition(reduceMotion ? AnyTransition.opacity : AnyTransition.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(reduceMotion ? Animation.easeInOut(duration: 0.15) : Animation.snappy(duration: 0.3), value: shown?.id)
            // Keyed on the object, not its id: reading an attribute of a catch deleted on another
            // tab can crash, and this key is worked out every time the body runs.
            .onChange(of: fishCatch.map { ObjectIdentifier($0) }, initial: true) {
                shown = fishCatch.map(LoggedToastContent.init)
                if let shown {
                    // The toast does not take focus, so VoiceOver users hear it instead.
                    UIAccessibility.post(notification: .announcement, argument: shown.message)
                }
            }
            .task(id: shown?.id) {
                guard shown != nil else { return }
                try? await Task.sleep(for: .seconds(4))
                // VoiceOver and Switch Control users may still be finding the Undo button, so it
                // waits for them.
                guard !Task.isCancelled, !UIAccessibility.isVoiceOverRunning,
                      !UIAccessibility.isSwitchControlRunning
                else { return }
                hide()
            }
    }

    /// Puts things back the way they were. A trip that logging this catch started, and that holds
    /// nothing else, goes too, so a stray Log does not leave a trip running with GPS on.
    private func undo() {
        if let fishCatch, !fishCatch.isDeleted, let context = fishCatch.modelContext {
            // Read before the delete, because reading a deleted model can crash. A trip started by
            // logging gets the catch's own time as its start; one started by hand always starts earlier.
            let trip = fishCatch.trip
            let startedByThisCatch = trip.map { $0.isActive && $0.startDate == fishCatch.timestamp } ?? false
            CatchLogger.delete(fishCatch, in: context)
            if let trip, startedByThisCatch, !trip.isDeleted, trip.modelContext != nil,
               !trip.catches.contains(where: { !$0.isDeleted && $0.modelContext != nil }) {
                // Also stops the sensors, because the trip is still running.
                CatchLogger.delete(trip, in: context)
            }
            Haptics.warning()
        }
        hide()
    }

    private func hide() {
        fishCatch = nil
    }
}

private struct LoggedToastContent: Equatable {
    let id: UUID
    let species: Species?
    let message: String

    init(_ fishCatch: FishCatch) {
        id = fishCatch.id
        species = fishCatch.species
        let name = fishCatch.speciesName
        message = fishCatch.count > 1 ? "\(fishCatch.count) \(name) logged" : "\(name) logged"
    }
}

private struct LoggedToastView: View {
    let content: LoggedToastContent
    let onUndo: () -> Void
    let onClose: () -> Void

    @Environment(AppSettings.self) private var settings
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    @Environment(\.accessibilitySwitchControlEnabled) private var switchControlEnabled

    var body: some View {
        let strong = settings.usesStrongContrast(colorSchemeContrast)
        let tapSize = settings.buttonSize.minTapSize
        HStack(spacing: 12) {
            SpeciesIcon(species: content.species, size: 32)
            Text(content.message)
                .font(.subheadline.weight(.semibold))
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button(action: onUndo) {
                Text("Undo")
                    .font(.subheadline.weight(.semibold))
                    .frame(minWidth: tapSize, minHeight: tapSize)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
            // Nothing hides the toast while VoiceOver or Switch Control runs, so it gets a way to close.
            if voiceOverEnabled || switchControlEnabled {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.subheadline.weight(.semibold))
                        .frame(minWidth: tapSize, minHeight: tapSize)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
                .accessibilityLabel("Close")
            }
        }
        .padding(.leading, 12)
        .padding(.trailing, 6)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .fill(strong ? AnyShapeStyle(Theme.cardBackground) : AnyShapeStyle(Material.regular))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .strokeBorder(strong ? Color.primary : Color.clear, lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.15), radius: 10, y: 4)
        .accessibilityElement(children: .contain)
        .accessibilityAction(.escape, onClose)
    }
}
