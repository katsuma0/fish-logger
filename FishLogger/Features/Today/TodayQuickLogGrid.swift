import SwiftUI

/// How a quick log tile is drawn. Rows take over at the largest text sizes, where names no longer
/// fit in a tile.
private enum TodayTileStyle {
    case tile, row
}

/// Plain name tiles on grouped cards, the way iOS draws them. One tap is one fish; a long press has
/// the rest.
struct TodayQuickLogGrid: View {
    let species: [Species]
    /// Fish caught this trip, by species id.
    let counts: [String: Int]
    /// The line under the tiles while there are no favourites yet.
    let footnote: String?
    let actions: TodayFishActions

    @Environment(AppSettings.self) private var settings
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    /// Tiles grow with the text so names have room for three lines.
    @ScaledMetric(relativeTo: .headline) private var baseTileHeight: CGFloat = 92
    @ScaledMetric(relativeTo: .headline) private var baseRowHeight: CGFloat = 60

    init(species: [Species], counts: [String: Int], footnote: String?, actions: TodayFishActions) {
        self.species = species
        self.counts = counts
        self.footnote = footnote
        self.actions = actions
    }

    var body: some View {
        let style = tileStyle
        let minHeight = style == .row
            ? max(settings.buttonSize.minTapSize, baseRowHeight * settings.buttonSize.scale)
            : baseTileHeight * settings.buttonSize.scale

        VStack(alignment: .leading, spacing: 8) {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(species) { item in
                    TodaySpeciesTile(
                        species: item,
                        count: counts[item.id] ?? 0,
                        style: style,
                        minHeight: minHeight,
                        actions: actions
                    )
                }
                TodayActionTile(
                    title: "Other fish",
                    systemImage: "magnifyingglass",
                    spokenLabel: "Other fish",
                    hint: "Pick any species from the full list",
                    style: style,
                    minHeight: minHeight,
                    action: actions.onOtherFish
                )
                TodayActionTile(
                    title: "Photo ID",
                    systemImage: "camera",
                    spokenLabel: "Photo ID",
                    hint: "Take or pick a photo and get a species suggestion",
                    style: style,
                    minHeight: minHeight,
                    action: actions.onPhotoID
                )
            }
            if let footnote {
                TodayFishFootnote(text: footnote)
            }
        }
    }

    private var tileStyle: TodayTileStyle {
        dynamicTypeSize >= .accessibility3 ? .row : .tile
    }

    /// Three or more across at normal sizes, two at the first accessibility sizes, then one list.
    private var columns: [GridItem] {
        if dynamicTypeSize >= .accessibility3 {
            return [GridItem(.flexible(), spacing: 10)]
        }
        if dynamicTypeSize.isAccessibilitySize {
            return [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]
        }
        // Big text in a narrow tile breaks names mid-word, so wider tiles from xLarge up.
        let widthScale: CGFloat = dynamicTypeSize >= .xLarge ? 1.25 : 1
        return [GridItem(.adaptive(minimum: settings.buttonSize.tileMinWidth * widthScale), spacing: 10)]
    }
}

/// The name in a tile. A one word name shrinks a little on one line rather than break mid-word.
private struct TodayTileName: View {
    let text: Text
    let isOneWord: Bool

    var body: some View {
        text
            .font(.headline)
            .lineLimit(isOneWord ? 1 : 3)
            .minimumScaleFactor(0.8)
    }
}

private struct TodaySpeciesTile: View {
    let species: Species
    let count: Int
    let style: TodayTileStyle
    let minHeight: CGFloat
    let actions: TodayFishActions

    @Environment(AppSettings.self) private var settings
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    /// Room above and below the name for the count in the corner, so a long name never runs under it.
    @ScaledMetric(relativeTo: .caption) private var countRoom: CGFloat = 24

    init(
        species: Species,
        count: Int,
        style: TodayTileStyle,
        minHeight: CGFloat,
        actions: TodayFishActions
    ) {
        self.species = species
        self.count = count
        self.style = style
        self.minHeight = minHeight
        self.actions = actions
    }

    var body: some View {
        let name = species.commonName
        let spokenLabel = "Log \(name.lowercased())"
        let spokenValue = count > 0 ? "\(count) caught this trip" : "None caught this trip"

        Button {
            actions.onLog(species, 1)
        } label: {
            label(name: name)
                .contentShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .todayFishMenu(species: species, count: count, actions: actions)
        .accessibilityLabel(spokenLabel)
        .accessibilityValue(spokenValue)
        .accessibilityHint("Logs one fish. Press and hold for more.")
    }

    @ViewBuilder
    private func label(name: String) -> some View {
        let nameView = TodayTileName(text: Text(name), isOneWord: !name.contains(" "))
            .foregroundStyle(.primary)
        switch style {
        case .tile:
            nameView
                .multilineTextAlignment(.center)
                .padding(.horizontal, 6)
                .padding(.vertical, countRoom)
                .frame(maxWidth: .infinity, minHeight: minHeight)
                .cardBackground()
                .overlay(alignment: .topTrailing) {
                    if count > 0 {
                        countBadge
                            .padding(6)
                    }
                }
        case .row:
            HStack(spacing: 12) {
                nameView
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                // Kept in the row at zero, just hidden, so the first fish does not re-wrap the name.
                countBadge
                    .opacity(count > 0 ? 1 : 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, minHeight: minHeight)
            .cardBackground()
        }
    }

    /// The running count in a small blue capsule. VoiceOver reads it as the tile's value instead.
    private var countBadge: some View {
        let strong = settings.usesStrongContrast(colorSchemeContrast)
        return Text("\(count)")
            .font(.caption.weight(.semibold))
            .monospacedDigit()
            .foregroundStyle(Color.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Capsule().fill(TodayFill.accent(strong: strong)))
            .accessibilityHidden(true)
    }
}

/// Other fish and Photo ID. Drawn like the fish tiles, with blue text and a small symbol, the way
/// iOS marks an action.
private struct TodayActionTile: View {
    let title: String
    let systemImage: String
    let spokenLabel: String
    let hint: String
    let style: TodayTileStyle
    let minHeight: CGFloat
    let action: () -> Void

    @Environment(AppSettings.self) private var settings
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    /// Same room as the fish tiles keep for their count, so a row of tiles lines up.
    @ScaledMetric(relativeTo: .caption) private var countRoom: CGFloat = 24

    init(
        title: String,
        systemImage: String,
        spokenLabel: String,
        hint: String,
        style: TodayTileStyle,
        minHeight: CGFloat,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.spokenLabel = spokenLabel
        self.hint = hint
        self.style = style
        self.minHeight = minHeight
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            label
                .contentShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(spokenLabel)
        .accessibilityHint(hint)
    }

    @ViewBuilder
    private var label: some View {
        let strong = settings.usesStrongContrast(colorSchemeContrast)
        // The symbol sits in the text, so it wraps with the words and scales with them.
        let titleView = TodayTileName(text: Text("\(Image(systemName: systemImage)) \(title)"), isOneWord: false)
            .foregroundStyle(strong ? Color.primary : Color.accentColor)
        switch style {
        case .tile:
            titleView
                .multilineTextAlignment(.center)
                .padding(.horizontal, 6)
                .padding(.vertical, countRoom)
                .frame(maxWidth: .infinity, minHeight: minHeight)
                .cardBackground()
        case .row:
            titleView
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, minHeight: minHeight)
                .cardBackground()
        }
    }
}
