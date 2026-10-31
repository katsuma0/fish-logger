import Charts
import SwiftUI

/// Fish per hour under each recorded condition. Rates, not counts, because nice days get longer trips.
struct StatsConditionsSection: View {
    let stats: StatsCalculator

    @Environment(AppSettings.self) private var settings

    init(stats: StatsCalculator) {
        self.stats = stats
    }

    /// Fewer trips than this and one lucky evening decides the whole chart.
    static let minimumTrips = 3

    var body: some View {
        let groups = conditionGroups

        StatsSectionCard("Conditions", footer: "Fish per hour fished, so long days do not skew it.") {
            VStack(alignment: .leading, spacing: 20) {
                ForEach(groups) { group in
                    StatsConditionBlock(group: group, scale: settings.buttonSize.scale)
                }
            }
        }
    }

    private var conditionGroups: [StatsConditionGroup] {
        let pressure = stats.ratesByPressureBucket(unit: settings.pressureUnit)
        let trend = stats.ratesByPressureTrend()
        let moon = stats.ratesByMoon()
        let weather = stats.ratesByWeather()
        let timeOfDay = stats.ratesByTimeOfDay()
        return [
            StatsConditionGroup(title: "Pressure", rates: pressure, recordedTrips: Self.tripTotal(pressure)),
            StatsConditionGroup(title: "Pressure trend", rates: trend, recordedTrips: Self.tripTotal(trend)),
            StatsConditionGroup(title: "Moon", rates: moon, recordedTrips: Self.tripTotal(moon)),
            StatsConditionGroup(title: "Weather", rates: weather, recordedTrips: Self.tripTotal(weather)),
            // A trip can span several parts of the day, so the plain trip count is the honest total.
            StatsConditionGroup(
                title: "Part of the day",
                rates: timeOfDay,
                recordedTrips: stats.tripCount,
                note: "Morning 5 to 11 am, midday 11 am to 4 pm, evening 4 to 9 pm, night the rest."
            )
        ]
    }

    private static func tripTotal(_ rates: [StatsCalculator.ConditionRate]) -> Int {
        rates.reduce(0) { $0 + $1.trips }
    }
}

struct StatsConditionGroup: Identifiable {
    let title: String
    let rates: [StatsCalculator.ConditionRate]
    let recordedTrips: Int
    var note: String? = nil

    var id: String { title }
}

private struct StatsConditionBlock: View {
    let group: StatsConditionGroup
    let scale: CGFloat

    var body: some View {
        let maxRate = group.rates.map(\.fishPerHour).max() ?? 0
        // Room on the right for the trip count label next to the longest bar.
        let upperBound = max(maxRate * 1.5, 0.5)
        let height = (CGFloat(max(1, group.rates.count)) * 36 + 28) * scale

        VStack(alignment: .leading, spacing: 8) {
            Text(group.title)
                .font(.subheadline.weight(.semibold))
                .accessibilityAddTraits(.isHeader)

            if group.recordedTrips < StatsConditionsSection.minimumTrips || group.rates.isEmpty {
                Text("Need at least 3 trips with this recorded.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Chart(group.rates) { rate in
                    BarMark(
                        x: .value("Fish per hour", rate.fishPerHour),
                        y: .value("Condition", rate.label)
                    )
                    .annotation(position: .trailing) {
                        Text(StatsFormat.trips(rate.trips))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel(rate.label)
                    .accessibilityValue("\(StatsFormat.rate(rate.fishPerHour)) fish per hour over \(StatsFormat.trips(rate.trips))")
                }
                .chartXScale(domain: 0...upperBound)
                .frame(height: height)
                .accessibilityLabel("\(group.title), fish per hour")
                .accessibilityValue(summary)

                if let note = group.note {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var summary: String {
        group.rates
            .map { "\($0.label) \(StatsFormat.rate($0.fishPerHour)) per hour" }
            .joined(separator: ", ")
    }
}
