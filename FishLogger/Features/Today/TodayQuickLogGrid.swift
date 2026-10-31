import SwiftUI

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
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: settings.buttonSize.tileMinWidth), spacing: 10)],
            spacing: 10
        ) {
            ForEach(species) { item in
                TodaySpeciesTile(
                    species: item,
                    count: counts[item.id] ?? 0,
                    onLog: { count in onLog(item, count) },
                    onLogWithDetails: { onLogWithDetails(item) }
                )
            }
            TodayActionTile(
                title: "Other fish",
                systemImage: "magnifyingglass",
                spokenLabel: "Other fish",
                hint: "Pick any species from the full list",
                action: onOtherFish
            )
            TodayActionTile(
                title: "Photo ID",
                systemImage: "camera.fill",
                spokenLabel: "Identify a fish from a photo",
                hint: "Take or pick a photo and get a species suggestion",
                action: onPhotoID
            )
        }
    }
}

private struct TodaySpeciesTile: View {
    let species: Species
    let count: Int
    let onLog: (Int) -> Void
    let onLogWithDetails: () -> Void

    @Environment(AppSettings.self) private var settings

    init(species: Species, count: Int, onLog: @escaping (Int) -> Void, onLogWithDetails: @escaping () -> Void) {
        self.species = species
        self.count = count
        self.onLog = onLog
        self.onLogWithDetails = onLogWithDetails
    }

    var body: some View {
        let name = species.commonName
        let isFavourite = settings.isFavourite(species.id)
        let spokenLabel = "Log \(name.lowercased())"
        let spokenValue = count > 0 ? "\(count) caught this trip" : "None caught this trip"

        Button {
            onLog(1)
        } label: {
            VStack(spacing: 6) {
                SpeciesIcon(species: species, size: settings.buttonSize.iconSize)
                Text(name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, minHeight: settings.buttonSize.tileHeight)
            .cardBackground(tint: species.color)
            .overlay(alignment: .topTrailing) {
                if count > 0 {
                    countBadge
                }
            }
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
                Haptics.tap()
                settings.toggleFavourite(species.id)
            } label: {
                if isFavourite {
                    Label("Remove from favourites", systemImage: "star.slash")
                } else {
                    Label("Add to favourites", systemImage: "star")
                }
            }
        }
        .accessibilityLabel(spokenLabel)
        .accessibilityValue(spokenValue)
        .accessibilityHint("Double tap to log one fish")
        .accessibilityAction(named: Text("Log with details")) { onLogWithDetails() }
    }

    private var countBadge: some View {
        Text("\(count)")
            .font(.caption.weight(.bold))
            .monospacedDigit()
            .foregroundStyle(Color.white)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Capsule().fill(species.color))
            .padding(6)
    }
}

private struct TodayActionTile: View {
    let title: String
    let systemImage: String
    let spokenLabel: String
    let hint: String
    let action: () -> Void

    @Environment(AppSettings.self) private var settings

    init(title: String, systemImage: String, spokenLabel: String, hint: String, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.spokenLabel = spokenLabel
        self.hint = hint
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
                    .frame(height: settings.buttonSize.iconSize)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, minHeight: settings.buttonSize.tileHeight)
            .cardBackground()
            .contentShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(spokenLabel)
        .accessibilityHint(hint)
    }
}
