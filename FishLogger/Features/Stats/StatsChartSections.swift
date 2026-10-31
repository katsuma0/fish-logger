import Charts
import SwiftUI

/// Horizontal bars, one per species, in the species colour.
struct StatsSpeciesChart: View {
    let items: [StatsCalculator.SpeciesCount]

    @Environment(AppSettings.self) private var settings

    init(items: [StatsCalculator.SpeciesCount]) {
        self.items = items
    }

    var body: some View {
        let maxCount = items.map(\.count).max() ?? 0
        let upperBound = maxCount + max(1, maxCount / 4)
        let rowHeight: CGFloat = 32
        let height = (CGFloat(max(1, items.count)) * rowHeight + 28) * settings.buttonSize.scale

        StatsSectionCard("By species") {
            Chart(items) { item in
                BarMark(
                    x: .value("Fish", item.count),
                    y: .value("Species", item.name)
                )
                .foregroundStyle(item.statsTint)
                .annotation(position: .trailing) {
                    Text("\(item.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel(item.name)
                .accessibilityValue(StatsFormat.fish(item.count))
            }
            .chartXScale(domain: 0...upperBound)
            .frame(height: height)
            .accessibilityLabel("Fish by species")
            .accessibilityValue(summary)
        }
    }

    private var summary: String {
        items.prefix(5)
            .map { "\($0.name) \($0.count)" }
            .joined(separator: ", ")
    }
}

/// Fish by the clock hour they were logged.
struct StatsHourChart: View {
    let items: [StatsCalculator.HourCount]

    @Environment(AppSettings.self) private var settings

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
                AxisMarks(values: ["12a", "3a", "6a", "9a", "12p", "3p", "6p", "9p"])
            }
            .frame(height: 180 * settings.buttonSize.scale)
            .accessibilityLabel("Fish by hour of day")
            .accessibilityValue(summary)
        }
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

    @Environment(AppSettings.self) private var settings

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
            .frame(height: 180 * settings.buttonSize.scale)
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

    @Environment(AppSettings.self) private var settings

    init(items: [StatsCalculator.SizeClassCount]) {
        self.items = items
    }

    var body: some View {
        let hasSizes = items.contains { $0.count > 0 }

        StatsSectionCard("Size classes", footer: "Measured fish are sorted into a class from their length.") {
            if hasSizes {
                Chart(items) { item in
                    BarMark(
                        x: .value("Size", item.sizeClass.label),
                        y: .value("Fish", item.count)
                    )
                    .accessibilityLabel(item.sizeClass.label)
                    .accessibilityValue(StatsFormat.fish(item.count))
                }
                .frame(height: 180 * settings.buttonSize.scale)
                .accessibilityLabel("Fish by size class")
                .accessibilityValue(summary)
            } else {
                Text("No sizes logged in this range. Pick a size class when you log a fish to fill this in.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
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
