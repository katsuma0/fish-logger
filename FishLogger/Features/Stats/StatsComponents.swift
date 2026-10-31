import SwiftUI

/// Heading, card, and optional footer. Every block on the Stats screen uses it so they line up.
struct StatsSectionCard<Content: View>: View {
    let title: String
    let footer: String?
    let content: Content

    init(_ title: String, footer: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.footer = footer
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            VStack(alignment: .leading, spacing: 12) {
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .cardBackground()
            if let footer {
                Text(footer)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

/// Number and word formatting used across the Stats views.
enum StatsFormat {
    static func fish(_ count: Int) -> String {
        "\(count) fish"
    }

    static func trips(_ count: Int) -> String {
        count == 1 ? "1 trip" : "\(count) trips"
    }

    static func rate(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(1)))
    }

    static func percent(_ share: Double) -> String {
        share.formatted(.percent.precision(.fractionLength(0)))
    }

    /// Compact axis label: "6a", "12p".
    static func hourLabel(_ hour: Int) -> String {
        let twelveHour = hour % 12 == 0 ? 12 : hour % 12
        let suffix = hour < 12 ? "a" : "p"
        return "\(twelveHour)\(suffix)"
    }

    /// What VoiceOver reads for an hour: "6 am".
    static func spokenHour(_ hour: Int) -> String {
        let twelveHour = hour % 12 == 0 ? 12 : hour % 12
        let suffix = hour < 12 ? "am" : "pm"
        return "\(twelveHour) \(suffix)"
    }

    /// "12 fish", or "12 fish, logged 9 times" when some catches held more than one fish.
    static func fishAndCatches(fish: Int, catches: Int) -> String {
        guard catches != fish else { return self.fish(fish) }
        let times = catches == 1 ? "once" : "\(catches) times"
        return "\(self.fish(fish)), logged \(times)"
    }

    /// "Moon", "Moon and Weather", "Pressure, Moon, and Weather", in the reader's language.
    static func list(_ items: [String]) -> String {
        items.formatted(.list(type: .and))
    }
}

/// Tallest a chart gets at large text sizes. Past this it pushes everything else off screen.
enum StatsLayout {
    static let maxChartHeight: CGFloat = 360
}

extension StatsCalculator.SpeciesCount {
    /// Bar colour for the species chart.
    var statsTint: Color { species?.color ?? Color.gray }
}

/// The row of headline numbers at the top of the screen.
struct StatsSummaryGrid: View {
    let stats: StatsCalculator

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(stats: StatsCalculator) {
        self.stats = stats
    }

    var body: some View {
        let columnCount = dynamicTypeSize.isAccessibilitySize ? 1 : 2
        let columns = Array(repeating: GridItem(.flexible(), spacing: 12, alignment: .top), count: columnCount)
        LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
            ForEach(tiles) { tile in
                StatsSummaryTile(tile: tile)
            }
        }
    }

    private var tiles: [StatsTileContent] {
        [
            StatsTileContent(label: "Fish", value: "\(stats.totalFish)", spokenValue: nil),
            StatsTileContent(label: "Trips", value: "\(stats.tripCount)", spokenValue: nil),
            StatsTileContent(label: "Days out", value: "\(stats.daysFished)", spokenValue: nil),
            StatsTileContent(label: "Species", value: "\(stats.speciesCount)", spokenValue: nil),
            StatsTileContent(
                label: "Fish per hour",
                value: stats.fishPerHour.map { StatsFormat.rate($0) } ?? "-",
                spokenValue: stats.fishPerHour == nil ? "not enough time logged" : nil
            ),
            StatsTileContent(
                label: "Skunked",
                value: stats.skunkRate.map { StatsFormat.percent($0) } ?? "-",
                spokenValue: stats.skunkRate == nil ? "no trips" : nil
            ),
            StatsTileContent(
                label: "Released",
                value: stats.releasedShare.map { StatsFormat.percent($0) } ?? "-",
                spokenValue: stats.releasedShare == nil ? "no fish" : nil
            )
        ]
    }
}

/// Label and value rows. Stands in for a chart at accessibility text sizes, where bar labels
/// would collide or shrink to nothing.
struct StatsValueRows: View {
    struct Row: Identifiable {
        let label: String
        let value: String

        var id: String { label }
    }

    let rows: [Row]

    init(rows: [Row]) {
        self.rows = rows
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(rows) { row in
                if row.id != rows.first?.id {
                    Divider()
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(row.label)
                        .font(.body)
                    Text(row.value)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
                .accessibilityElement(children: .combine)
            }
        }
    }
}

/// Removable capsule for an active filter, matching the Trips tab. The whole chip is the remove button.
struct StatsFilterChip: View {
    let title: String
    let species: Species?
    let systemImage: String?
    let onRemove: () -> Void

    @Environment(AppSettings.self) private var settings
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    init(title: String, species: Species?, systemImage: String?, onRemove: @escaping () -> Void) {
        self.title = title
        self.species = species
        self.systemImage = systemImage
        self.onRemove = onRemove
    }

    var body: some View {
        let strong = settings.usesStrongContrast(colorSchemeContrast)
        Button(action: onRemove) {
            HStack(spacing: 6) {
                if let species {
                    SpeciesIcon(species: species, size: 18)
                } else if let systemImage {
                    Image(systemName: systemImage)
                        .font(.caption)
                        .accessibilityHidden(true)
                }
                // No line limit: the chips sit in a horizontal scroll view, so the full name always fits.
                Text(title)
                    .font(.subheadline.weight(.medium))
                Image(systemName: "xmark.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            .padding(.leading, 8)
            .padding(.trailing, 10)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(Color.accentColor.opacity(strong ? 0.3 : 0.15))
            )
            .overlay(
                Capsule().strokeBorder(
                    strong ? Color.primary : Color.clear,
                    lineWidth: strong ? 1.5 : 0
                )
            )
            .frame(minHeight: settings.buttonSize.minTapSize)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Remove filter: \(title)")
    }
}

struct StatsTileContent: Identifiable {
    let label: String
    let value: String
    /// Replaces the value for VoiceOver when the printed value is a placeholder.
    let spokenValue: String?

    var id: String { label }
}

private struct StatsSummaryTile: View {
    let tile: StatsTileContent

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(tile.value)
                .font(.title2.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(tile.label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .cardBackground()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(tile.label), \(tile.spokenValue ?? tile.value)")
    }
}
