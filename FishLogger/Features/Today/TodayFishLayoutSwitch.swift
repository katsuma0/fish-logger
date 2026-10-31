import SwiftUI
import UIKit

/// Tiles or List for the fish on Today, drawn like a small iOS segmented control. Each half is a
/// button at least as tall as the Button size setting asks, so it is easy to hit with wet hands,
/// while the part you see stays the size of a stock control.
struct TodayFishLayoutSwitch: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @ScaledMetric(relativeTo: .subheadline) private var baseSegmentHeight: CGFloat = 28
    @ScaledMetric(relativeTo: .subheadline) private var baseSegmentWidth: CGFloat = 44

    init() {}

    var body: some View {
        let strong = settings.usesStrongContrast(colorSchemeContrast)
        let selection = settings.todayFishLayout
        let scale = settings.buttonSize.scale
        let segmentHeight = baseSegmentHeight * scale
        let segmentWidth = max(settings.buttonSize.minTapSize, baseSegmentWidth * scale)
        let trackHeight = segmentHeight + 4
        let tapHeight = max(settings.buttonSize.minTapSize, trackHeight)
        let track = RoundedRectangle(cornerRadius: 9, style: .continuous)

        HStack(spacing: 0) {
            ForEach(TodayFishLayout.allCases) { layout in
                TodayFishLayoutSegment(
                    layout: layout,
                    isSelected: layout == selection,
                    strong: strong,
                    width: segmentWidth,
                    height: segmentHeight,
                    tapHeight: tapHeight
                )
            }
        }
        .padding(.horizontal, 2)
        .background {
            track
                .fill(Color(uiColor: .tertiarySystemFill))
                .frame(height: trackHeight)
        }
        .overlay {
            track
                .strokeBorder(strong ? Color.primary : Color.clear, lineWidth: 1.5)
                .frame(height: trackHeight)
                .allowsHitTesting(false)
        }
        .fixedSize()
    }
}

private struct TodayFishLayoutSegment: View {
    let layout: TodayFishLayout
    let isSelected: Bool
    let strong: Bool
    let width: CGFloat
    let height: CGFloat
    let tapHeight: CGFloat

    @Environment(AppSettings.self) private var settings

    /// White in light mode and a lighter grey in dark mode, like the selected half of a segmented
    /// control.
    private static let selectedFill = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.systemGray2.resolvedColor(with: traits)
            : UIColor.white
    })

    init(layout: TodayFishLayout, isSelected: Bool, strong: Bool, width: CGFloat, height: CGFloat, tapHeight: CGFloat) {
        self.layout = layout
        self.isSelected = isSelected
        self.strong = strong
        self.width = width
        self.height = height
        self.tapHeight = tapHeight
    }

    var body: some View {
        let pill = RoundedRectangle(cornerRadius: 7, style: .continuous)
        Button {
            guard settings.todayFishLayout != layout else { return }
            settings.todayFishLayout = layout
        } label: {
            Image(systemName: layout.systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected && strong ? Color.white : Color.primary)
                .frame(width: width, height: height)
                .background {
                    if isSelected {
                        pill
                            .fill(strong ? TodayFill.accent(strong: true) : Self.selectedFill)
                            .shadow(color: Color.black.opacity(strong ? 0 : 0.12), radius: 2, x: 0, y: 1)
                    }
                }
                .frame(height: tapHeight)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(layout.label)
        .accessibilityHint(hint)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var hint: String {
        switch layout {
        case .tiles: "Shows the fish as tiles"
        case .list: "Shows the fish as a list"
        }
    }
}
