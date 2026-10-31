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
