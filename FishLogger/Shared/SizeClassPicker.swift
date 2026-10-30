import SwiftUI

/// One row of size buttons: Dink, Small, Medium, Large, Trophy. Tapping the selected one clears it.
/// Shows the species' length range under each label so the buckets mean the same thing every trip.
struct SizeClassPicker: View {
    @Binding var selection: SizeClass?
    let species: Species?
    var showsRanges: Bool = true

    @Environment(AppSettings.self) private var settings

    var body: some View {
        HStack(spacing: 6) {
            ForEach(SizeClass.allCases) { sizeClass in
                button(for: sizeClass)
            }
        }
    }

    private func button(for sizeClass: SizeClass) -> some View {
        let isSelected = selection == sizeClass
        let range = species.map { settings.lengthRangeLabel($0, sizeClass) } ?? ""
        return Button {
            Haptics.tap()
            selection = isSelected ? nil : sizeClass
        } label: {
            VStack(spacing: 2) {
                Text(sizeClass.label)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if showsRanges, !range.isEmpty {
                    Text(range)
                        .font(.caption2)
                        .lineLimit(2)
                        .minimumScaleFactor(0.6)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(isSelected ? Color.white.opacity(0.9) : Color.secondary)
                }
            }
            .frame(maxWidth: .infinity, minHeight: settings.buttonSize.minTapSize)
            .padding(.vertical, 4)
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? Color.accentColor : Color(uiColor: .tertiarySystemFill))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(settings.highContrast ? Color.primary : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(range.isEmpty ? sizeClass.label : "\(sizeClass.label), \(range)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
