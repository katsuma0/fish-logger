import SwiftData
import SwiftUI
import UIKit

/// Date wording shared by the Today cards.
enum TodayFormat {
    /// "at 6:10 AM", "yesterday at 6:10 AM", or "Oct 29 at 6:10 AM", so a trip left running
    /// overnight is easy to spot.
    static func when(_ date: Date, now: Date = .now) -> String {
        let time = date.formatted(date: .omitted, time: .shortened)
        let calendar = Calendar.current
        if calendar.isDate(date, inSameDayAs: now) { return "at \(time)" }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
           calendar.isDate(date, inSameDayAs: yesterday) {
            return "yesterday at \(time)"
        }
        let day = date.formatted(.dateTime.month(.abbreviated).day())
        return "\(day) at \(time)"
    }
}

/// Summary card for the running trip: where, and how many once the first fish is in. Conditions live
/// in their own card below the tiles, so chips filling in as the weather arrives never push the grid down.
struct TodayTripHeader: View {
    let trip: Trip
    let speciesCount: Int
    let onEdit: () -> Void

    @Environment(AppSettings.self) private var settings
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(trip: Trip, speciesCount: Int, onEdit: @escaping () -> Void) {
        self.trip = trip
        self.speciesCount = speciesCount
        self.onEdit = onEdit
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button(action: onEdit) {
                HStack(alignment: .center, spacing: 12) {
                    Image(systemName: trip.waterBody.symbolName)
                        .font(.title2)
                        .foregroundStyle(Color.accentColor)
                        .frame(minWidth: 32)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(trip.displayName)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    Spacer(minLength: 8)
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.tertiary)
                        .accessibilityHidden(true)
                }
                .frame(minHeight: settings.buttonSize.minTapSize)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint("Edit the spot and conditions")

            // No counts until something is logged, so a new trip shows only the spot.
            if trip.totalFish > 0 {
                statRow
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardBackground()
    }

    private var subtitle: String {
        "\(trip.method.label), \(trip.waterBody.label.lowercased()). Started \(TodayFormat.when(trip.startDate))."
    }

    /// Side by side normally; stacked at accessibility sizes so nothing truncates.
    private var statRow: some View {
        let stacked = dynamicTypeSize.isAccessibilitySize
        let layout = stacked
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 6))
            : AnyLayout(HStackLayout(alignment: .lastTextBaseline, spacing: 24))
        let fish = trip.totalFish

        return layout {
            statBlock(
                value: "\(fish)",
                caption: "fish",
                spoken: fish == 1 ? "1 fish" : "\(fish) fish",
                prominent: true,
                stacked: stacked
            )
            .fixedSize(horizontal: !stacked, vertical: false)
            // Unknown fish add to the fish total but not to species, so skip a lone "0 species".
            if speciesCount > 0 {
                statBlock(
                    value: "\(speciesCount)",
                    caption: "species",
                    spoken: "\(speciesCount) species",
                    prominent: false,
                    stacked: stacked
                )
                .fixedSize(horizontal: !stacked, vertical: false)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func statBlock(value: String, caption: String, spoken: String, prominent: Bool, stacked: Bool) -> some View {
        let valueText = Text(value)
            .font(prominent ? Font.largeTitle.bold() : Font.title2.bold())
            .monospacedDigit()
        let captionText = Text(caption)
            .font(.caption)
            .foregroundStyle(.secondary)

        Group {
            if stacked {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    valueText
                    captionText
                }
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    valueText
                    captionText
                }
            }
        }
        .frame(maxWidth: stacked ? .infinity : nil, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spoken)
    }
}

/// The running trip's conditions and the weather button. Sits below the tiles: it grows as GPS and
/// weather fill in, and that must not move the grid.
struct TodayConditionsCard: View {
    let trip: Trip
    let isFetchingWeather: Bool
    let onGetWeather: () -> Void

    @Environment(AppSettings.self) private var settings

    init(trip: Trip, isFetchingWeather: Bool, onGetWeather: @escaping () -> Void) {
        self.trip = trip
        self.isFetchingWeather = isFetchingWeather
        self.onGetWeather = onGetWeather
    }

    var body: some View {
        if ConditionsSummaryView.hasConditions(trip) || showsWeatherButton {
            VStack(alignment: .leading, spacing: 8) {
                Text("Conditions")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                VStack(alignment: .leading, spacing: 12) {
                    ConditionsSummaryView(trip: trip)
                    if showsWeatherButton {
                        weatherButton
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardBackground()
            }
        }
    }

    private var showsWeatherButton: Bool {
        settings.autoFetchWeather && trip.coordinate != nil && trip.weather == nil && trip.weatherFetchedAt == nil
    }

    private var weatherButton: some View {
        Button(action: onGetWeather) {
            HStack(spacing: 8) {
                if isFetchingWeather {
                    ProgressView()
                } else {
                    Image(systemName: "cloud.sun")
                        .accessibilityHidden(true)
                }
                Text(isFetchingWeather ? "Getting weather" : "Get weather")
            }
            .font(.subheadline.weight(.semibold))
            .frame(minHeight: settings.buttonSize.minTapSize)
        }
        .buttonStyle(.bordered)
        .disabled(isFetchingWeather)
    }
}
