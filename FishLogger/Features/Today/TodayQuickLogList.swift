import SwiftUI
import UIKit

/// The fish on Today as an inset grouped list: the name on the left, this trip's count on the right.
/// A tap logs one fish, and a long press has the same menu as a tile. Other fish and Photo ID sit in
/// a group of their own below, the way iOS keeps actions apart from items.
struct TodayQuickLogList: View {
    let species: [Species]
    /// Fish caught this trip, by species id.
    let counts: [String: Int]
    /// The line under the fish while there are no favourites yet.
    let footnote: String?
    let actions: TodayFishActions

    @Environment(AppSettings.self) private var settings
    @ScaledMetric(relativeTo: .body) private var baseRowHeight: CGFloat = 44

    init(species: [Species], counts: [String: Int], footnote: String?, actions: TodayFishActions) {
        self.species = species
        self.counts = counts
        self.footnote = footnote
        self.actions = actions
    }

    var body: some View {
        let rowHeight = max(settings.buttonSize.minTapSize, baseRowHeight * settings.buttonSize.scale)
        let firstID = species.first?.id

        VStack(alignment: .leading, spacing: 0) {
            if !species.isEmpty {
                TodayListGroup {
                    ForEach(species) { item in
                        if item.id != firstID {
                            TodayListSeparator()
                        }
                        TodaySpeciesRow(
                            species: item,
                            count: counts[item.id] ?? 0,
                            minHeight: rowHeight,
                            actions: actions
                        )
                    }
                }
            }
            if let footnote {
                TodayFishFootnote(text: footnote)
                    .padding(.top, 8)
            }
            TodayListGroup {
                TodayListActionRow(
                    title: "Other fish",
                    systemImage: "magnifyingglass",
                    hint: "Pick any species from the full list",
                    minHeight: rowHeight,
                    action: actions.onOtherFish
                )
                TodayListSeparator()
                TodayListActionRow(
                    title: "Photo ID",
                    systemImage: "camera",
                    hint: "Take or pick a photo and get a species suggestion",
                    minHeight: rowHeight,
                    action: actions.onPhotoID
                )
            }
            .padding(.top, species.isEmpty && footnote == nil ? 0 : 20)
        }
    }
}

/// One rounded group of rows, like a section of an inset grouped list. High contrast adds the
/// same hard border as the cards.
private struct TodayListGroup<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
        .cardBackground()
    }
}

/// The hairline between rows, inset to line up with the text. Solid with high contrast.
private struct TodayListSeparator: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    init() {}

    var body: some View {
        Group {
            if settings.usesStrongContrast(colorSchemeContrast) {
                Rectangle()
                    .fill(Color.primary)
                    .frame(height: 1)
            } else {
                Divider()
            }
        }
        .padding(.leading, 16)
        .accessibilityHidden(true)
    }
}

/// A row's own fill, grey while pressed like a tapped list row. The fill also gives the long-press
/// preview a solid background.
private struct TodayListRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Color(uiColor: .systemGray4) : Theme.cardBackground)
    }
}

private struct TodaySpeciesRow: View {
    let species: Species
    let count: Int
    let minHeight: CGFloat
    let actions: TodayFishActions

    @Environment(AppSettings.self) private var settings
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    init(species: Species, count: Int, minHeight: CGFloat, actions: TodayFishActions) {
        self.species = species
        self.count = count
        self.minHeight = minHeight
        self.actions = actions
    }

    var body: some View {
        let name = species.commonName
        let strong = settings.usesStrongContrast(colorSchemeContrast)
        let spokenValue = count > 0 ? "\(count) caught this trip" : "None caught this trip"

        Button {
            actions.onLog(species, 1)
        } label: {
            HStack(spacing: 12) {
                Text(name)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if count > 0 {
                    Text("\(count)")
                        .font(.body)
                        .monospacedDigit()
                        .foregroundStyle(strong ? Color.primary : Color.secondary)
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, minHeight: minHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(TodayListRowButtonStyle())
        .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
        .todayFishMenu(species: species, count: count, actions: actions)
        .accessibilityLabel("Log \(name.lowercased())")
        .accessibilityValue(spokenValue)
        .accessibilityHint("Logs one fish. Press and hold for more.")
    }
}

/// Other fish and Photo ID: blue text with a small symbol, the way iOS marks an action row.
private struct TodayListActionRow: View {
    let title: String
    let systemImage: String
    let hint: String
    let minHeight: CGFloat
    let action: () -> Void

    @Environment(AppSettings.self) private var settings
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    init(title: String, systemImage: String, hint: String, minHeight: CGFloat, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.hint = hint
        self.minHeight = minHeight
        self.action = action
    }

    var body: some View {
        let strong = settings.usesStrongContrast(colorSchemeContrast)
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.body)
                .foregroundStyle(strong ? Color.primary : Color.accentColor)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .frame(minHeight: minHeight)
                .contentShape(Rectangle())
        }
        .buttonStyle(TodayListRowButtonStyle())
        .accessibilityLabel(title)
        .accessibilityHint(hint)
    }
}
