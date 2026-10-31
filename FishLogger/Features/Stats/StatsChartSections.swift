import Charts
import SwiftUI

/// Fish per species, most first, as rows with a bar under each name in the species colour.
/// Rows rather than a bar chart so long names wrap at any text size, and each row is a button
/// that narrows the whole screen to that species.
struct StatsSpeciesChart: View {
    let items: [StatsCalculator.SpeciesCount]
    let onSelect: (String) -> Void

    init(items: [StatsCalculator.SpeciesCount], onSelect: @escaping (String) -> Void = { _ in }) {
        self.items = items
        self.onSelect = onSelect
    }

    var body: some View {
        let maxCount = max(1, items.map(\.count).max() ?? 1)

        StatsSectionCard("By species", footer: "Tap a species to see only its stats.") {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(items) { item in
                    if item.id != items.first?.id {
                        Divider()
                    }
                    Button {
                        onSelect(item.speciesID)
                    } label: {
                        StatsSpeciesRow(item: item, fraction: CGFloat(item.count) / CGFloat(maxCount))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(item.name)
                    .accessibilityValue(StatsFormat.fish(item.count))
                    .accessibilityHint("Shows only \(item.name).")
                }
            }
        }
    }
}

private struct StatsSpeciesRow: View {
    let item: StatsCalculator.SpeciesCount
    /// This species' count over the top count, 0 to 1.
    let fraction: CGFloat

    @Environment(AppSettings.self) private var settings
    @ScaledMetric(relativeTo: .caption) private var barHeight: CGFloat = 8

    init(item: StatsCalculator.SpeciesCount, fraction: CGFloat) {
        self.item = item
        self.fraction = fraction
    }

    var body: some View {
        HStack(spacing: 12) {
            SpeciesIcon(species: item.species, size: settings.buttonSize.iconSize)
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(item.name)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 8)
                    Text("\(item.count)")
                        .font(.body.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                GeometryReader { proxy in
                    Capsule()
                        .fill(item.statsTint)
                        .frame(width: max(barHeight, proxy.size.width * fraction), height: barHeight)
                }
                .frame(height: barHeight)
            }
        }
        .padding(.vertical, 8)
        .frame(minHeight: settings.buttonSize.minTapSize)
        .contentShape(Rectangle())
    }
}

/// Fish by the clock hour they were logged.
struct StatsHourChart: View {
    let items: [StatsCalculator.HourCount]

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .caption) private var chartHeight: CGFloat = 180

    init(items: [StatsCalculator.HourCount]) {
        self.items = items
    }

    var body: some View {
        StatsSectionCard("Time of day", footer: "Fish by the hour they were logged.") {
            Chart(items) { item in
                BarMark(
                    x: .value("Hour", StatsFormat.hourLabel(item.hour)),
                    y: .value("Fish", item.count)
                )
                .accessibilityLabel(StatsFormat.spokenHour(item.hour))
                .accessibilityValue(StatsFormat.fish(item.count))
            }
            .chartXAxis {
                AxisMarks(values: axisHours)
            }
            .frame(height: min(chartHeight, StatsLayout.maxChartHeight))
            .accessibilityLabel("Fish by hour of day")
            .accessibilityValue(summary)
        }
    }

    /// Fewer labels at accessibility sizes, so the bigger text does not run together.
    private var axisHours: [String] {
        if dynamicTypeSize.isAccessibilitySize {
            return ["12a", "6a", "12p", "6p"]
        }
        return ["12a", "3a", "6a", "9a", "12p", "3p", "6p", "9p"]
    }

    /// Names the busiest hours so VoiceOver users get the point without stepping through 24 bars.
    private var summary: String {
        let busiest = items
            .filter { $0.count > 0 }
            .sorted { $0.count == $1.count ? $0.hour < $1.hour : $0.count > $1.count }
            .prefix(3)
            .map { "\(StatsFormat.spokenHour($0.hour)) \(StatsFormat.fish($0.count))" }
        return busiest.isEmpty ? "No fish" : "Busiest: " + busiest.joined(separator: ", ")
    }
}

/// Fish per month for months with at least one trip.
struct StatsMonthChart: View {
    let items: [StatsCalculator.MonthCount]

    @ScaledMetric(relativeTo: .caption) private var chartHeight: CGFloat = 180

    init(items: [StatsCalculator.MonthCount]) {
        self.items = items
    }

    var body: some View {
        StatsSectionCard("By month") {
            Chart(items) { item in
                BarMark(
                    x: .value("Month", item.month, unit: .month),
                    y: .value("Fish", item.count)
                )
                .accessibilityLabel(item.month.formatted(.dateTime.month(.wide).year()))
                .accessibilityValue("\(StatsFormat.fish(item.count)), \(StatsFormat.trips(item.trips))")
            }
            .frame(height: min(chartHeight, StatsLayout.maxChartHeight))
            .accessibilityLabel("Fish by month")
            .accessibilityValue(summary)
        }
    }

    private var summary: String {
        guard let best = items.max(by: { $0.count < $1.count }), best.count > 0 else { return "No fish" }
        return "Best month: \(best.month.formatted(.dateTime.month(.wide).year())), \(StatsFormat.fish(best.count))"
    }
}

/// How many fish fell in each size class.
struct StatsSizeChart: View {
    let items: [StatsCalculator.SizeClassCount]

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .caption) private var chartHeight: CGFloat = 180

    init(items: [StatsCalculator.SizeClassCount]) {
        self.items = items
    }

    var body: some View {
        let hasSizes = items.contains { $0.count > 0 }

        StatsSectionCard("Size classes", footer: "Measured fish are sorted into a class from their length.") {
            if !hasSizes {
                Text("No sizes logged in this range. Pick a size class when you log a fish to fill this in.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else if dynamicTypeSize.isAccessibilitySize {
                // Five labels under five bars do not fit at these sizes, so read it as a list.
                StatsValueRows(rows: items.map {
                    StatsValueRows.Row(label: $0.sizeClass.label, value: StatsFormat.fish($0.count))
                })
            } else {
                Chart(items) { item in
                    BarMark(
                        x: .value("Size", item.sizeClass.label),
                        y: .value("Fish", item.count)
                    )
                    .accessibilityLabel(item.sizeClass.label)
                    .accessibilityValue(StatsFormat.fish(item.count))
                }
                .frame(height: min(chartHeight, StatsLayout.maxChartHeight))
                .accessibilityLabel("Fish by size class")
                .accessibilityValue(summary)
            }
        }
    }

    private var summary: String {
        items
            .filter { $0.count > 0 }
            .map { "\($0.sizeClass.label) \($0.count)" }
            .joined(separator: ", ")
    }
}
