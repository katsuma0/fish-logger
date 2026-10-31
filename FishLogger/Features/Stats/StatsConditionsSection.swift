import Charts
import SwiftUI

/// Fish per hour under each recorded condition. Rates, not counts, because nice days get longer trips.
/// The groups arrive worked out and already trimmed to those with enough trips, so this view
/// only draws.
struct StatsConditionsSection: View {
    let groups: [StatsConditionGroup]
    /// Titles of the groups left out for having too few trips.
    let hiddenTitles: [String]

    init(groups: [StatsConditionGroup], hiddenTitles: [String] = []) {
        self.groups = groups
        self.hiddenTitles = hiddenTitles
    }

    /// Fewer trips than this and one lucky evening decides the whole chart.
    static let minimumTrips = StatsLimits.minimumConditionTrips

    var body: some View {
        StatsSectionCard("Conditions", footer: groups.isEmpty ? nil : "Fish per hour fished, so long days do not skew it.") {
            if groups.isEmpty {
                Text("Condition charts show up after \(Self.minimumTrips) trips with weather, pressure, or moon recorded.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(groups) { group in
                        StatsConditionBlock(group: group)
                    }
                    if let hiddenNote {
                        Text(hiddenNote)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    /// One line naming the charts still waiting on data, so they do not seem to be missing.
    private var hiddenNote: String? {
        guard !hiddenTitles.isEmpty else { return nil }
        let names = StatsFormat.list(hiddenTitles)
        if hiddenTitles.count == 1 {
            return "\(names) shows up after \(Self.minimumTrips) trips with it recorded."
        }
        return "\(names) show up after \(Self.minimumTrips) trips with them recorded."
    }
}

private struct StatsConditionBlock: View {
    let group: StatsConditionGroup

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    /// Per bar. Grows with text size so the labels beside each bar keep their room.
    @ScaledMetric(relativeTo: .caption) private var rowHeight: CGFloat = 36
    /// Room for the axis under the bars.
    @ScaledMetric(relativeTo: .caption) private var axisHeight: CGFloat = 28

    init(group: StatsConditionGroup) {
        self.group = group
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(group.title)
                .font(.subheadline.weight(.semibold))
                .accessibilityAddTraits(.isHeader)

            if dynamicTypeSize.isAccessibilitySize {
                // Long labels such as "Low (under 100.5 kPa)" crowd out the bars at these sizes.
                StatsValueRows(rows: group.rates.map { rate in
                    StatsValueRows.Row(label: rate.label, value: spokenRate(rate))
                })
            } else {
                chart
            }

            if let note = group.note {
                Text(note)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var chart: some View {
        let maxRate = group.rates.map(\.fishPerHour).max() ?? 0
        // Room on the right for the trip count label next to the longest bar.
        let upperBound = max(maxRate * 1.5, 0.5)
        let height = CGFloat(max(1, group.rates.count)) * rowHeight + axisHeight

        return Chart(group.rates) { rate in
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
            .accessibilityValue(spokenRate(rate))
        }
        .chartXScale(domain: 0...upperBound)
        .frame(height: height)
        .accessibilityLabel("\(group.title), fish per hour")
        .accessibilityValue(summary)
    }

    private func spokenRate(_ rate: StatsCalculator.ConditionRate) -> String {
        "\(StatsFormat.rate(rate.fishPerHour)) fish per hour over \(StatsFormat.trips(rate.trips))"
    }

    private var summary: String {
        group.rates
            .map { "\($0.label) \(StatsFormat.rate($0.fishPerHour)) per hour" }
            .joined(separator: ", ")
    }
}
