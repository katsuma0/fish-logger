import SwiftUI

/// Size buttons: Dink, Small, Medium, Large, Trophy. Tapping the selected one clears it.
/// Shows the species' length range under each label so the buckets mean the same thing every trip.
/// One row at normal text sizes; a grid at larger and accessibility sizes so labels never truncate.
struct SizeClassPicker: View {
    @Binding var selection: SizeClass?
    let species: Species?
    var showsRanges: Bool = true

    @Environment(AppSettings.self) private var settings
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    var body: some View {
        let columns = columnCount
        if columns >= SizeClass.allCases.count {
            HStack(spacing: 6) {
                ForEach(SizeClass.allCases) { sizeClass in
                    button(for: sizeClass)
                }
            }
            // Lets every button grow to the tallest one, so the row reads as one control.
            .fixedSize(horizontal: false, vertical: true)
        } else {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: columns), spacing: 6) {
                ForEach(SizeClass.allCases) { sizeClass in
                    button(for: sizeClass)
                }
            }
        }
    }

    /// Five across up to the default text size, where every label fits even on a small iPhone.
    /// Three at the larger standard sizes, two at the first accessibility sizes (the app's Huge
    /// setting is one of them), and a single column above that.
    private var columnCount: Int {
        switch dynamicTypeSize {
        case .xLarge, .xxLarge, .xxxLarge: 3
        case .accessibility1, .accessibility2, .accessibility3: 2
        case .accessibility4, .accessibility5: 1
        default: SizeClass.allCases.count
        }
    }

    /// At accessibility sizes the range would crowd the label, so it is only spoken.
    private var showsRangeText: Bool {
        showsRanges && !dynamicTypeSize.isAccessibilitySize
    }

    private func button(for sizeClass: SizeClass) -> some View {
        let isSelected = selection == sizeClass
        let range = species.map { settings.lengthRangeLabel($0, sizeClass) } ?? ""
        let strong = settings.usesStrongContrast(colorSchemeContrast)
        let fitsOneRow = columnCount >= SizeClass.allCases.count
        return Button {
            Haptics.tap()
            selection = isSelected ? nil : sizeClass
        } label: {
            VStack(spacing: 2) {
                Text(sizeClass.label)
                    .font(.subheadline.weight(.semibold))
                    // In the single row a long word shrinks a little instead of breaking mid-word.
                    // The grid has room, so labels wrap there.
                    .lineLimit(fitsOneRow ? 1 : 3)
                    .minimumScaleFactor(0.85)
                    .multilineTextAlignment(.center)
                if showsRangeText, !range.isEmpty {
                    Text(range)
                        .font(.caption2)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(isSelected ? Color.white : Color.secondary)
                }
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 2)
            // Stretching to the row's height only applies in the single row; grid cells size to fit.
            .frame(
                maxWidth: .infinity,
                minHeight: settings.buttonSize.minTapSize,
                maxHeight: fitsOneRow ? CGFloat.infinity : nil
            )
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? Theme.accentFillColor(strong: strong) : Color(uiColor: .tertiarySystemFill))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(strong ? Color.primary : Color.clear, lineWidth: isSelected && strong ? 3 : 1.5)
            )
            .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(range.isEmpty ? sizeClass.label : "\(sizeClass.label), \(range)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
