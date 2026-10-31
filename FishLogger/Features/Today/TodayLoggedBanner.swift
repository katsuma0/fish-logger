import SwiftUI
import UIKit

/// Plain values for the logged banner, so the banner never reads a model that Undo just deleted.
struct TodayLoggedInfo: Equatable {
    let catchID: UUID
    let title: String
    let subtitle: String
    let species: Species?
}

/// Confirmation after a log, with the one extra tap most fish deserve: a size.
struct TodayLoggedBanner: View {
    let info: TodayLoggedInfo
    @Binding var sizeClass: SizeClass?
    let onDetails: () -> Void
    let onUndo: () -> Void

    @Environment(AppSettings.self) private var settings

    init(
        info: TodayLoggedInfo,
        sizeClass: Binding<SizeClass?>,
        onDetails: @escaping () -> Void,
        onUndo: @escaping () -> Void
    ) {
        self.info = info
        self._sizeClass = sizeClass
        self.onDetails = onDetails
        self.onUndo = onUndo
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 10) {
                SpeciesIcon(species: info.species, size: 34)
                VStack(alignment: .leading, spacing: 2) {
                    Text(info.title)
                        .font(.headline)
                    Text(info.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.green)
                    .accessibilityHidden(true)
            }
            .accessibilityElement(children: .combine)

            SizeClassPicker(selection: $sizeClass, species: info.species)

            HStack(spacing: 10) {
                Button(action: onDetails) {
                    Label("Details", systemImage: "square.and.pencil")
                        .frame(maxWidth: .infinity, minHeight: settings.buttonSize.minTapSize)
                }
                .buttonStyle(.bordered)
                .accessibilityHint("Opens everything for this catch")

                Button(role: .destructive, action: onUndo) {
                    Label("Undo", systemImage: "arrow.uturn.backward")
                        .frame(maxWidth: .infinity, minHeight: settings.buttonSize.minTapSize)
                }
                .buttonStyle(.bordered)
                .accessibilityHint("Removes this catch")
            }
            .font(.headline)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .fill(settings.highContrast ? AnyShapeStyle(Theme.cardBackground) : AnyShapeStyle(Material.regular))
                .shadow(color: Color.black.opacity(0.18), radius: 12, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .strokeBorder(settings.highContrast ? Color.primary : Color.clear, lineWidth: 2)
        )
    }
}

/// Floating shortcut to photo ID. Sits on the thumb side the angler picked in Settings.
struct TodayCameraButton: View {
    let action: () -> Void

    @Environment(AppSettings.self) private var settings

    init(action: @escaping () -> Void) {
        self.action = action
    }

    var body: some View {
        let size = settings.buttonSize.primaryButtonHeight
        Button(action: action) {
            Image(systemName: "camera.fill")
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color.white)
                .frame(width: size, height: size)
                .background(Circle().fill(Color.accentColor))
                .overlay {
                    Circle()
                        .strokeBorder(settings.highContrast ? Color.primary : Color.clear, lineWidth: 2)
                }
                .shadow(color: Color.black.opacity(0.25), radius: 6, x: 0, y: 3)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Identify a fish from a photo")
        .accessibilityHint("Opens the camera, or your photos when there is no camera")
    }
}
