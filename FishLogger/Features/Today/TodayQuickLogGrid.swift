import SwiftUI

/// How a quick log tile is drawn. Rows take over at the largest text sizes, where names no longer
/// fit in a tile.
private enum TodayTileStyle {
    case tile, row
}

/// Big species tiles. One tap is one fish; a long press has the rest.
struct TodayQuickLogGrid: View {
    let species: [Species]
    /// Fish caught this trip, by species id.
    let counts: [String: Int]
    let onLog: (Species, Int) -> Void
    let onLogWithDetails: (Species) -> Void
    let onOtherFish: () -> Void
    let onPhotoID: () -> Void

    @Environment(AppSettings.self) private var settings
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    /// Tiles grow with the text so names have room for three lines.
    @ScaledMetric(relativeTo: .subheadline) private var baseTileHeight: CGFloat = 92
    @ScaledMetric(relativeTo: .subheadline) private var baseRowHeight: CGFloat = 60

    init(
        species: [Species],
        counts: [String: Int],
        onLog: @escaping (Species, Int) -> Void,
        onLogWithDetails: @escaping (Species) -> Void,
        onOtherFish: @escaping () -> Void,
        onPhotoID: @escaping () -> Void
    ) {
        self.species = species
        self.counts = counts
        self.onLog = onLog
        self.onLogWithDetails = onLogWithDetails
        self.onOtherFish = onOtherFish
        self.onPhotoID = onPhotoID
    }

    var body: some View {
        let style = tileStyle
        let minHeight = style == .row
            ? max(settings.buttonSize.minTapSize, baseRowHeight * settings.buttonSize.scale)
            : baseTileHeight * settings.buttonSize.scale

        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(species) { item in
                TodaySpeciesTile(
                    species: item,
                    count: counts[item.id] ?? 0,
                    style: style,
                    minHeight: minHeight,
                    onLog: { count in onLog(item, count) },
                    onLogWithDetails: { onLogWithDetails(item) }
                )
            }
            TodayActionTile(
                title: "Other fish",
                systemImage: "magnifyingglass",
                spokenLabel: "Other fish",
                hint: "Pick any species from the full list",
                style: style,
                minHeight: minHeight,
                action: onOtherFish
            )
            TodayActionTile(
                title: "Photo ID",
                systemImage: "camera.fill",
                spokenLabel: "Photo ID",
                hint: "Take or pick a photo and get a species suggestion",
                style: style,
                minHeight: minHeight,
                action: onPhotoID
            )
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
        // Big text in a narrow tile breaks names mid-word, so wider tiles from xxLarge up.
        let widthScale: CGFloat = dynamicTypeSize >= .xxLarge ? 1.25 : 1
        return [GridItem(.adaptive(minimum: settings.buttonSize.tileMinWidth * widthScale), spacing: 10)]
    }
}

private struct TodaySpeciesTile: View {
    let species: Species
    let count: Int
    let style: TodayTileStyle
    let minHeight: CGFloat
    let onLog: (Int) -> Void
    let onLogWithDetails: () -> Void

    @Environment(AppSettings.self) private var settings

    init(
        species: Species,
        count: Int,
        style: TodayTileStyle,
        minHeight: CGFloat,
        onLog: @escaping (Int) -> Void,
        onLogWithDetails: @escaping () -> Void
    ) {
        self.species = species
        self.count = count
        self.style = style
        self.minHeight = minHeight
        self.onLog = onLog
        self.onLogWithDetails = onLogWithDetails
    }

    var body: some View {
        let name = species.commonName
        let isFavourite = settings.isFavourite(species.id)
        let spokenLabel = "Log \(name.lowercased())"
        let spokenValue = count > 0 ? "\(count) caught this trip" : "None caught this trip"
        let favouriteTitle = isFavourite ? "Remove from favourites" : "Add to favourites"

        Button {
            onLog(1)
        } label: {
            label(name: name)
                .contentShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button { onLog(2) } label: { Label("Log 2", systemImage: "2.circle") }
            Button { onLog(3) } label: { Label("Log 3", systemImage: "3.circle") }
            Button { onLog(5) } label: { Label("Log 5", systemImage: "5.circle") }
            Button { onLogWithDetails() } label: { Label("Log with details", systemImage: "square.and.pencil") }
            Divider()
            Button {
                settings.toggleFavourite(species.id)
            } label: {
                Label(favouriteTitle, systemImage: isFavourite ? "star.slash" : "star")
            }
        }
        .accessibilityLabel(spokenLabel)
        .accessibilityValue(spokenValue)
        .accessibilityHint("Logs one fish.")
        .accessibilityAction(named: Text("Log 2")) { onLog(2) }
        .accessibilityAction(named: Text("Log 3")) { onLog(3) }
        .accessibilityAction(named: Text("Log 5")) { onLog(5) }
        .accessibilityAction(named: Text("Log with details")) { onLogWithDetails() }
        .accessibilityAction(named: Text(favouriteTitle)) { settings.toggleFavourite(species.id) }
    }

    @ViewBuilder
    private func label(name: String) -> some View {
        switch style {
        case .tile:
            VStack(spacing: 6) {
                SpeciesIcon(species: species, size: settings.buttonSize.iconSize)
                nameText(name)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, minHeight: minHeight)
            .cardBackground(tint: species.color)
            .overlay(alignment: .topTrailing) {
                if count > 0 {
                    countBadge
                        .padding(6)
                }
            }
        case .row:
            HStack(spacing: 12) {
                SpeciesIcon(species: species, size: settings.buttonSize.iconSize)
                nameText(name)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if count > 0 {
                    countBadge
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, minHeight: minHeight)
            .cardBackground(tint: species.color)
        }
    }

    private func nameText(_ name: String) -> some View {
        Text(name)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.primary)
            .lineLimit(3)
            .minimumScaleFactor(0.85)
    }

    private var countBadge: some View {
        Text("\(count)")
            .font(.caption.weight(.bold))
            .monospacedDigit()
            .foregroundStyle(Color.white)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Capsule().fill(species.color))
            .accessibilityHidden(true)
    }
}

private struct TodayActionTile: View {
    let title: String
    let systemImage: String
    let spokenLabel: String
    let hint: String
    let style: TodayTileStyle
    let minHeight: CGFloat
    let action: () -> Void

    @Environment(AppSettings.self) private var settings

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
        switch style {
        case .tile:
            VStack(spacing: 6) {
                icon
                titleText
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, minHeight: minHeight)
            .cardBackground()
        case .row:
            HStack(spacing: 12) {
                icon
                    .frame(width: settings.buttonSize.iconSize)
                titleText
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, minHeight: minHeight)
            .cardBackground()
        }
    }

    private var icon: some View {
        Image(systemName: systemImage)
            .font(.title2.weight(.semibold))
            .foregroundStyle(Color.accentColor)
            .frame(height: settings.buttonSize.iconSize)
            .accessibilityHidden(true)
    }

    private var titleText: some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.primary)
            .lineLimit(3)
            .minimumScaleFactor(0.85)
    }
}
