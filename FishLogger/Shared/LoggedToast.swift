import SwiftData
import SwiftUI
import UIKit

extension View {
    /// Bottom toast for a catch logged outside the Today screen: species icon, "Walleye logged",
    /// Undo. Undo deletes the catch through CatchLogger. Hides after 4 s, never while VoiceOver runs.
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
            .onChange(of: fishCatch?.id, initial: true) {
                shown = fishCatch.map(LoggedToastContent.init)
                if let shown {
                    // The toast does not take focus, so VoiceOver users hear it instead.
                    UIAccessibility.post(notification: .announcement, argument: shown.message)
                }
            }
            .task(id: shown?.id) {
                guard shown != nil else { return }
                try? await Task.sleep(for: .seconds(4))
                // VoiceOver users may still be finding the Undo button, so it waits for them.
                guard !Task.isCancelled, !UIAccessibility.isVoiceOverRunning else { return }
                hide()
            }
    }

    private func undo() {
        if let fishCatch, !fishCatch.isDeleted, let context = fishCatch.modelContext {
            CatchLogger.delete(fishCatch, in: context)
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
            // Nothing hides the toast while VoiceOver runs, so it gets a way to close.
            if voiceOverEnabled {
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
